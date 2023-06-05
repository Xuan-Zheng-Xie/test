#!/bin/bash

# Configs
# the token will expire in 7/3
access_token="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"
#vm_name username hostname port
config=(
    [0]="debian11-x64 root 192.168.122.253 22"
    [1]="debian11-x86 root 192.168.122.72 22"
)

function Boot_VM(){
  echo Booting ${vm_name}
  while true; do
      vm_state=$(virsh domstate "$vm_name")
      if [[ "$vm_state" == "running" ]]; then
          echo "$vm_name is booted"
          break
      else
          virsh --connect qemu:///system start $vm_name
          break
      fi
  done
}

function Deploy_Linux(){
  # Clone from repository
  Clone_rep="\
    cd /home/eric; \
    mkdir -p Adlink; \
    cd ./Adlink; \
    rm -f -r edgego-agent; \
    git clone "https://${access_token}@github.com/Xuan-Zheng-Xie/edgego-agent.git"; \
  "

  # Build package
  Build_pac="\
    cd "/home/eric/Adlink/edgego-agent/build${os_type}Package"; \
    bash build.sh; \
  "

  ssh -p "$port" "$username@$hostname" "\
    "${Clone_rep}"\
    "${Build_pac}"\
  "
}

function Extract_Linux(){
  echo Extracting Files From ${vm_name}
  targets=(edgegoagent.deb edgegoupgrade.deb vncservice.deb)
  cd /home/eric/Desktop
  mkdir -p Adlink
  cd ./Adlink
  mkdir -p BuildPackges_${vm_name}
  des_path=/home/eric/Desktop/Adlink/BuildPackges_${vm_name}
  for target in ${targets[@]}; do
    tar_path=${username}@${hostname}:/home/eric/Adlink/edgego-agent/build${os_type}Package/${target}
    scp ${tar_path} ${des_path}
  done
}

function Deploy_Win(){
  echo todo
}

function Extract_Win(){
  echo todo
}

function Shutdown_VM(){
  echo Shutdown ${vm_name}
  virsh --connect qemu:///system shutdown ${vm_name}
}

# Running
for ((i=0; i<${#config[@]}; i++)); do
  row=(${config[$i]})
  vm_name=${row[0]}
  username=${row[1]}
  hostname=${row[2]}
  port=${row[3]}
  
  # Booting
  Boot_VM

  # Deploying
  temp=$(echo "$vm_name" | grep -o 'A-Za-z')
  if [ $temp=="debian" ]; then
    os_type="Linux"
    echo "waiting for booting..."
    sleep 10
    Deploy_Linux
    Extract_Linux
  elif [ $temp=="win" ]; then
    os_type="Win"
    echo "waiting for booting..."
    sleep 30
    Deploy_Win
    Extract_Win
  else
    echo "OS type is not Supported"
  fi

  # Shutdown
  Shutdown_VM
  echo "waiting for shutdown..."
  sleep 10
done