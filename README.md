# nas-mount-helper

Ubuntu で NAS を `/mnt/...` に永続マウントし、Docker コンテナから bind mount で参照できるようにするための最小ツールです。

## このツールの狙い

要件に対して、次の構成を採用します。

- GUI は `zenity` を使ったシェルウィザード
- 実マウントは `mount.cifs`
- 永続化は `/etc/fstab`
- 認証情報は root 専用の `/etc/nas-mount-helper/credentials/*.cred`
- 設定直後に即時マウントして成功/失敗を確認
- 起動時復旧は `network-online.target` と Docker 起動順を考慮した `fstab` オプションで吸収

この方針にすると、独自デーモンや大きい GUI アプリを持たずに済み、Ubuntu 標準の仕組みに寄せられます。

## なぜこの方式か

### 要件との対応

1. `/mnt/...` にマウントするので Docker の bind mount 元として使える
2. GVFS や `/run/user/...` を使わない
3. `/etc/fstab` により再起動後も自動復旧できる
4. パスワードは root のみ読める credential file に保存する
5. GUI は `zenity` だけなのでメンテコストが低い
6. 設定後すぐ `mount` を実行するので、その場で動作確認できる

### 採用しないもの

- 独自マウントデーモン
- FUSE 実装
- 大きい GUI アプリ
- Docker volume plugin
- 複雑な systemd unit 群

## ファイル構成

- `src/bin/nas-mount-helper`
  - 一般ユーザーが起動する GUI ウィザード
- `src/libexec/nas-mount-helper-apply`
  - `pkexec` 経由で root として実行される適用処理
- `src/libexec/nas-mount-helper-install-cifs-utils`
  - JetPack 5.1 / Ubuntu 20.04 で `cifs-utils` を自己インストールする処理
- `scripts/build-release-assets.sh`
  - GitHub Releases 用の `setup.sh` と `payload.tar.gz` を生成する内部スクリプト

## 前提

JetPack 5.1 / Ubuntu 20.04 側に以下が必要です。

- `zenity`
- `pkexec`

`cifs-utils` が無い場合、GUI が検出してその場で自己インストールします。

## ローカル実行

リポジトリを clone した状態なら次でそのままセットアップを起動できます。

```bash
./src/bin/nas-mount-helper
```

## `curl | sh` 配布

JetPack 5.1 向けに `curl | sh` で配布したい場合は、public GitHub repository の Releases を使います。

```bash
git tag v2026.04.10
git push origin v2026.04.10
```

または GitHub Actions の `Release` workflow を `workflow_dispatch` で実行し、tag を指定します。

workflow は内部で次の 2 ファイルを生成し、GitHub Release asset として公開します。

- `setup.sh`
- `payload.tar.gz`

前提:

- repository は public
- GitHub Actions が有効
- workflow が `contents: write` で release を作れる

利用者は次でインストールできます。

```bash
curl -fsSL https://github.com/<owner>/<repo>/releases/latest/download/setup.sh | sh
```

### 配布時の流れ

1. tag push または manual dispatch で GitHub Actions が起動
2. `scripts/build-release-assets.sh` が `setup.sh` と `payload.tar.gz` を生成
3. workflow が `gh release create` で release asset を公開
4. 利用者側の `setup.sh` が `releases/latest/download/payload.tar.gz` を取得
5. 一時展開した GUI スクリプトがそのままセットアップを実行し、終了後は破棄される

## セットアップイメージ

1. ユーザーが `nas-mount-helper` を起動
2. `cifs-utils` が無ければ GUI が検出し、管理者権限で自動インストール
3. GUI フォームに以下を入力
   - NAS ホスト
   - 共有名
   - マウント名
   - ユーザー名
   - パスワード
   - 任意でドメイン、UID、GID、SMB バージョン
4. 確認ダイアログで内容を確認
5. `pkexec` で root 権限昇格
6. root 側で以下を実施
   - `/mnt/<name>` を作成
   - credential file を root:root 0600 で保存
   - `/etc/fstab` の管理ブロックを更新
   - `mount /mnt/<name>` を即時実行
7. 成功なら Docker で `/mnt/<name>:/data` を使える

## `/etc/fstab` に書く内容

典型的には次のような行を生成します。

```fstab
//nas.local/media /mnt/media cifs credentials=/etc/nas-mount-helper/credentials/media.cred,iocharset=utf8,vers=3.0,_netdev,nofail,x-systemd.requires=network-online.target,x-systemd.after=network-online.target,x-systemd.before=docker.service,uid=1000,gid=1000,file_mode=0664,dir_mode=0775 0 0
```

### オプションの意図

- `credentials=...`
  - 平文パスワードをコマンドラインに出さない
- `_netdev`
  - ネットワークマウントとして扱う
- `nofail`
  - 一時的に NAS が遅くてもブート全体を壊しにくくする
- `x-systemd.requires=network-online.target`
  - ネットワーク確立後を待つ
- `x-systemd.after=network-online.target`
  - 起動順をネットワーク後ろに寄せる
- `x-systemd.before=docker.service`
  - Docker より前にマウントを試みる

## 即時確認

このツールは設定保存後にすぐ `mount /mnt/<name>` を実行します。

そのため、再起動せずに次が確認できます。

- マウント成功
- 認証失敗
- NAS 名解決失敗
- SMB バージョン不一致
- `/mnt/<name>` の参照可否

## Docker での利用例

```yaml
services:
  app:
    image: busybox
    command: ["sh", "-c", "ls -la /data && sleep infinity"]
    volumes:
      - /mnt/media:/data
```

## 制約

- 現在は CIFS/SMB 前提です
- Ubuntu 標準の権限昇格とマウント機構に依存します
- Docker Compose 側でさらに強い起動順保証が必要なら、`RequiresMountsFor=` を別途足す余地があります

## 今後の拡張候補

- NFS 対応
- 既存設定の再編集
- 接続テストだけ先に行うモード
- `.deb` 化してダブルクリックインストール対応
