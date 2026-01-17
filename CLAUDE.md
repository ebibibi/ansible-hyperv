# CLAUDE.md

このファイルはClaude Codeへの指示を記載しています。

## 最初に読むべきドキュメント

**重要**: 作業を開始する前に、必ず `design.md` を読んでください。

`design.md` には以下の情報が含まれています：
- リポジトリの全体構造
- Playbookの処理フロー
- カスタムモジュールの使い方
- 設定ファイルの構造
- 拡張方法

## プロジェクト概要

このリポジトリはAnsibleを使用してHyper-V上にWindows VM環境を自動構築します。Active Directoryフォレストの構築も可能です。

## 主要ファイル

- `create_vms.yml` - VM作成
- `create_ad.yml` - AD環境構築
- `remove_vms.yml` - VM削除
- `vars/Environments.yml` - VM/AD定義
- `hosts` - Ansibleインベントリ

## 実行環境

このリポジトリは以下の環境で動作しています：

### Hyper-Vホスト（Windows）
- このサーバー自体がHyper-Vホストです
- `powershell -Command "Get-VM"` でVM一覧を確認できます
- Hyper-V関連の操作（VM作成・削除・設定変更など）はPowerShellコマンドを使用します

### WSL（Windows Subsystem for Linux）
- リポジトリは `/mnt/d/repos/ansible-hyperv/` としてWSLからアクセス可能です
- Ansibleの実行はWSL上で行います
- WSLコマンド例: `wsl ansible-playbook -i //mnt/d/repos/ansible-hyperv/hosts ...`

### 作業時の使い分け
- **Hyper-V操作**: PowerShellを使用（`powershell -Command "..."`）
- **Ansible実行**: WSLを使用（`wsl ...`）
- **ファイル編集**: Windows側のパス（`D:\repos\ansible-hyperv\`）を使用
- WSLからWindowsパスにアクセスする際は `//mnt/d/...` 形式を使用（パス変換回避のため）
