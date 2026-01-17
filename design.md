# Ansible Hyper-V リポジトリ設計ドキュメント

このドキュメントはリポジトリの構造と設計思想を記録したリファレンスです。

## 概要

Hyper-Vサーバー上にWindows VMを自動構築し、Active Directoryフォレストを含む企業環境を構成するAnsibleプロジェクトです。

## ディレクトリ構造

```
ansible-hyperv/
├── hosts                    # Ansibleインベントリ（ホスト/VMのIP定義）
├── create_vms.yml           # VM作成Playbook
├── create_ad.yml            # AD環境構築Playbook
├── remove_vms.yml           # VM削除Playbook
├── vars/
│   └── Environments.yml     # VM/AD環境定義（重要）
├── group_vars/
│   ├── all/
│   │   ├── vars.yml         # 共通設定（WinRM接続）
│   │   └── vault.yml        # 暗号化パスワード
│   └── hyperv.yml           # Hyper-Vホスト固有設定
├── tasks/                   # 再利用可能タスク
│   ├── prov_vm.yml          # VMプロビジョニング
│   ├── config_vm.yml        # VM設定
│   ├── create_ad_forest.yml # ADフォレスト作成
│   ├── join_domain.yml      # ドメイン参加
│   └── add_ad_dcs.yml       # 追加DC構成
├── library/                 # カスタムAnsibleモジュール
│   ├── win_hyperv_guest.*   # VM作成/削除/起動/停止
│   ├── win_hyperv_guest_config_net.* # ゲスト内ネットワーク設定
│   └── win_mssql_database.ps1 # SQL Server DB管理
├── sysprep/                 # Sysprep応答ファイル
└── forAzureNestedHyperV/    # Azure Nested Hyper-V用
```

## アーキテクチャ

### ネットワーク構成

```
[Ansibleコントローラー (WSL Ubuntu)]
            │
            │ WinRM over HTTPS (Port 5986)
            ▼
    [Hyper-Vホスト] 172.25.32.1
            │
     [仮想スイッチ: Nested NAT Switch]
            │
    ┌───────┼───────────────────┐
    │       │       │       │   │
 [DC01]  [DC02]  [WIN11] [FS] [CONNECT]
10.1.1.1 10.1.1.2  ...    ...   ...
    └─────── AD Domain ────────┘
         (dev1.ebisuda.net)
```

### 接続方式

- **プロトコル**: WinRM over HTTPS
- **ポート**: 5986
- **認証**: Administrator + Vaultで管理するパスワード
- **証明書検証**: 無効化（自己署名証明書対応）

## 主要Playbook

### 1. create_vms.yml - VM作成

```bash
ansible-playbook -i hosts create_vms.yml --ask-vault-pass
```

**処理フロー**:
1. Hyper-VホストでVMをプロビジョニング（prov_vm.yml）
   - ゴールドイメージからVHDクローン
   - VM作成・ネットワーク設定
   - WinRM接続待機
2. ゲストVMで初期設定（config_vm.yml）
   - コンピュータ名設定
   - Dドライブ初期化

### 2. create_ad.yml - AD環境構築

```bash
ansible-playbook -i hosts create_ad.yml --ask-vault-pass
```

**処理フロー**:
1. VM作成（上記と同じ）
2. DC01でADフォレスト作成（create_ad_forest.yml）
   - NTP設定
   - AD-DSインストール
   - ドメイン/フォレスト作成
   - DNS逆引きゾーン作成
3. 他VMのドメイン参加（join_domain.yml）
4. DC02をDCに昇格（add_ad_dcs.yml）

### 3. remove_vms.yml - VM削除

```bash
ansible-playbook -i hosts remove_vms.yml --ask-vault-pass
```

## カスタムモジュール

### win_hyperv_guest

Hyper-V VMのライフサイクル管理。

**パラメータ**:
| パラメータ | 説明 | デフォルト |
|-----------|------|----------|
| name | VM名（必須） | - |
| state | present/absent/started/stopped/poweroff | - |
| memory | メモリ量 | 512MB |
| cpu | CPU数 | 1 |
| generation | VM世代 | 2 |
| network_switch | 仮想スイッチ名 | - |
| diskpath | システムVHDパス | - |
| d_diskpath | DドライブVHDパス | - |
| d_disksize | DドライブVHDサイズ | 500GB |

**使用例**:
```yaml
- win_hyperv_guest:
    name: "{{ item.name }}"
    state: present
    cpu: "{{ item.cpu }}"
    memory: "{{ item.memory }}"
    generation: "{{ defaut_generation }}"
    network_switch: "{{ item.network_switch }}"
    diskpath: "{{ item.dest_vhd }}"
```

### win_hyperv_guest_config_net

ゲストOS内のネットワーク設定（WMI経由）。

**パラメータ**:
| パラメータ | 説明 | デフォルト |
|-----------|------|----------|
| name | VM名（必須） | - |
| type | dhcp/static | dhcp |
| ip | 静的IP | - |
| netmask | ネットマスク | - |
| gateway | デフォルトゲートウェイ | - |
| dns | DNSサーバー | - |

**使用例**:
```yaml
- win_hyperv_guest_config_net:
    name: "{{ item.name }}"
    type: static
    ip: "{{ item.network.ip }}"
    netmask: "{{ item.network.netmask }}"
    gateway: "{{ item.network.gateway }}"
    dns: "{{ item.network.dns }}"
```

## 設定ファイル

### vars/Environments.yml

環境全体の定義ファイル。VMとADフォレストの設定を記述。

```yaml
vms:
  - type: windows
    name: "dc01"
    cpu: 2
    memory: 10240MB
    network:
      ip: 10.1.1.1
      netmask: 255.255.255.0
      gateway: 10.1.1.254
      dns: 10.1.1.1
    network_switch: 'Nested NAT Switch'
    src_vhd: "D:\\vhd\\win2022-gold.vhdx"
    dest_vhd: "D:\\vhd\\dc01.vhdx"
    d_diskpath: "D:\\vhd\\dc01_D.vhdx"
    d_disksize: 500GB

forest:
  domain_name: "dev1.ebisuda.net"
  recovery_password: "{{ vault_ansible_password }}"
  upstream_dns_1: 172.25.32.1
  upstream_dns_2: 8.8.8.8
  reverse_dns_zone: "10.1.1.0/24"
  ntp_servers: "0.jp.pool.ntp.org,1.jp.pool.ntp.org"
```

### hosts

Ansibleインベントリ。グループ分けが重要。

```ini
[hyperv]
172.25.32.1              # Hyper-Vホスト

[windows]                # 全ゲストVM
10.1.1.1 computername=dc01
10.1.1.2 computername=dc02
...

[firstDC]                # 最初のDC（フォレスト作成用）
10.1.1.1

[domainMembers]          # ドメイン参加するVM
10.1.1.2
10.1.1.4
10.1.1.5

[DCs]                    # 追加DC
10.1.1.2
```

## セキュリティ

### Ansible Vault

パスワードは`group_vars/all/vault.yml`で暗号化管理。

```bash
# 作成
ansible-vault create group_vars/all/vault.yml

# 編集
ansible-vault edit group_vars/all/vault.yml

# 内容例
vault_ansible_password: "your_password"
vault_host_password: "host_password"
```

### .gitignore

機密ファイルの除外:
- `group_vars/all/vault.yml`
- `forAzureNestedHyperV/sas.txt`

## ゴールドイメージ作成

Sysprep応答ファイルを使用してマスターVMを一般化。

```powershell
c:\windows\system32\sysprep\sysprep.exe `
    /generalize /oobe /shutdown `
    /unattend:win2022datacenter.xml
```

応答ファイル（sysprep/*.xml）の主要設定:
- 言語: ja-JP
- キーボード: 日本語
- タイムゾーン: Tokyo Standard Time
- 管理者パスワード設定
- EULA自動同意

## 拡張ポイント

### 新しいVMを追加

1. `vars/Environments.yml`にVM定義を追加
2. `hosts`に該当グループへエントリ追加
3. ゴールドイメージを`src_vhd`パスに配置

### 新しいタスクを追加

1. `tasks/`に新しいymlファイル作成
2. 適切なPlaybookから`include_tasks`で呼び出し

### カスタムモジュール追加

1. `library/`にPythonドキュメント（.py）とPowerShell実装（.ps1）を配置
2. Ansible標準のモジュール形式に従う

## 依存関係

### Ansible Collections

- `ansible.windows`: Windowsモジュール
- `microsoft.ad`: Active Directoryモジュール
- `community.windows`: 追加Windowsモジュール

### 前提条件

- Hyper-Vサーバー（Windows Server 2012 R2以降）
- WinRM有効化（HTTPS、ポート5986）
- Sysprep済みゴールドイメージ
- Ansibleコントローラー（Linux推奨）

## トラブルシューティング

### WinRM接続エラー

1. WinRMサービス確認: `winrm quickconfig`
2. HTTPSリスナー確認: `winrm enumerate winrm/config/listener`
3. ファイアウォール確認: ポート5986開放
4. 証明書確認: 自己署名証明書の有効期限

### VM作成失敗

1. ゴールドイメージパス確認
2. 仮想スイッチ名確認
3. ディスク空き容量確認
4. Hyper-V管理者権限確認

### AD構築失敗

1. DNS設定確認（upstream DNS到達性）
2. NTP同期確認
3. ドメイン名の妥当性確認
4. 再起動完了待機時間の調整
