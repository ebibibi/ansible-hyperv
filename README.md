# 紹介

Ansibleを用いてHyper-V + WindowsでInfrastructure as Codeを実現します。

これは下記からforkされたものです。

 - tsailiming/ansible-hyperv: Sample Ansible Playbook to provision VM on HyperV https://github.com/tsailiming/ansible-hyperv

理解しやすいようにより単純化されており、最新のWindows Server 2022で動作確認しています。


# 前提条件

* Hyper-Vサーバーが必要です
* Hyper-VサーバーはAnsibleで管理可能(WinRM有効化)な状態である必要があります。
* Ansibleで管理可能なWindows Server 2012 R2以降のsysprep実行済みイメージファイル。

# Playbooks

## VM作成

1. VM作成のパラーメーターは `vars/TestEnvironments.yml` に記載されています。こちらのファイルを希望に合わせて編集してください。
1. `hosts` に生成するVMのIPアドレスでエントリを追加します。
1. `create_vm.yml` を実行することで仮想マシンが実際に作成されます。

    ansible-playbook -i hosts create_vm.yml

## VM削除

    ansible-playbook -i hosts delete_vm.yml

## より詳しい利用方法

実際に環境およびsysprep実行済みイメージの準備～playbook実行までをYoutubeで解説していますので、参考にしてください。

* https://www.youtube.com/watch?v=qcGGHG_aoRY&list=PLas-S4LkjlLr27Dy5x80qUNvVFCPDb9fX

下記のドキュメントも準備に利用してください。

* https://github.com/ebibibi/ansible-hyperv/blob/master/prepare.md