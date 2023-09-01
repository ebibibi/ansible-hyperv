# このドキュメントについて

このレポジトリにあるplaybookが実行できるようになるまでの手順です。

## Hyper-Vホスト準備

Hyper-Vのホストはどのように準備しても構いませんが、検証用環境構築の目的での利用であればNested Hyper-Vを有効化したホストを利用するのが環境依存部分がなくなりお勧めです。下記動画を参考にしてください。

* [Nested Hyper\-Vで検証基盤を準備 / 企業でよくあるWindows, M365環境を構築してみるシリーズ Part1 \- YouTube](https://www.youtube.com/watch?v=5rG_3MxpFzQ&list=PLas-S4LkjlLr27Dy5x80qUNvVFCPDb9fX&index=3)
## Windows上でWinRMを有効化し、Ansibleで管理可能にする(PowerShellコンソールで実行)

    Invoke-WebRequest -Uri https://gist.githubusercontent.com/ebibibi/e0ad7a2401442d03a128fb359f5e6411/raw/1e9a95ad094a11ff3bda1bb5a17985b2c9812cbf/ConfigureRemotingForAnsible.ps1 -OutFile ConfigureRemotingForAnsible.ps1
    powershell -ExecutionPolicy RemoteSigned .\ConfigureRemotingForAnsible.ps1

## Ansible実行環境をWSL上に準備する(PowerShellコンソールで実行)

    wsl --install -d ubuntu

コマンド実行後Windowsを再起動します。再起動後にログインすると構成が自動的に継続されます。


## WSL上のUbuntu環境を最新の状態にする(WSL上で実行)

    sudo apt update
    sudo apt upgrade

## WSL上へのAnsible導入(WSL上で実行)

    sudo apt install python3-pip git libffi-dev libssl-dev -y
    pip install pywinrm
    sudo apt install ansible

## boxstarterを使ったgit, vscodeのインストール(PowerShellコンソールで実行)

    . { iwr -useb https://boxstarter.org/bootstrapper.ps1 } | iex; Get-Boxstarter -Force
    Install-BoxstarterPackage -PackageName https://gist.githubusercontent.com/ebibibi/cc53c859f2af91737889c2a6f6eb0aa5/raw/bb47a879f30597ed11b351eb09ad5969dce5071f/boxstarter.txt

## このGithubレポジトリをローカルにクローン(PowerShellコンソールで実行)

    e:
    mkdir e:\repos
    cd repos
    git clone https://github.com/ebibibi/ansible-hyperv.git
    Cd ansible-hyperv

## Windows Serverのsysprep実行済みイメージを作成する

コマンドのみでというわけにもいかないので、下記のYoutube動画をご覧ください。
* [sysprepでWindows Serverの雛形を作成する / 企業でよくあるWindows, M365環境を構築してみるシリーズ Part2 \- YouTube](https://www.youtube.com/watch?v=m5pFUegs6CY&list=PLas-S4LkjlLr27Dy5x80qUNvVFCPDb9fX&index=3)
* [ADK, SIMを使って応答ファイルを作成しsysprep実行後の構成を自動化する / 企業でよくあるWindows, M365環境を構築してみるシリーズ Part3 \- YouTube](https://www.youtube.com/watch?v=wOHfoPphjMY&list=PLas-S4LkjlLr27Dy5x80qUNvVFCPDb9fX&index=4)

応答ファイルは下記が使えます。
* https://gist.github.com/ebibibi/7c22b53ba6d8d9742a415994c5592bfc

### (ホストではなくマスターにするVM上の操作)Windows上でWinRMを有効化し、Ansibleで管理可能にする(PowerShellコンソールで実行)

    Invoke-WebRequest -Uri  https://gist.githubusercontent.com/ebibibi/e0ad7a2401442d03a128fb359f5e6411/raw/1e9a95ad094a11ff3bda1bb5a17985b2c9812cbf/ConfigureRemotingForAnsible.ps1 -OutFile ConfigureRemotingForAnsible.ps1
    powershell -ExecutionPolicy RemoteSigned .\ConfigureRemotingForAnsible.ps1

### (ホストではなくマスターにするVM上の操作)自動応答ファイルをc:\windows\system32\sysprepに配置したうえでsysprep実行

    # Win2022_answerfile.xmlをc:\windows\system32\sysprepにコピー
    c:\windows\system32\sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:win2022_answerfile.xml

## sysprep実行済みイメージを任意の場所に配置

配置した場所を `Environments.yml` 上に記載してください。

以上で準備は完了です。playbookが実行可能です。

## playbook実行方法(の例)
- WSL2を起動
- cd /mnt/e/repos/ansible-hyperv (※gitレポジトリまで移動)
- ansible-playbook -i hosts create_ad.yml
