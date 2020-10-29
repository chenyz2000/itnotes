- 创建会话

  ```shell
  tmux #自动创建会话，按数字依次命名
  tmux new -s <session-name>  #创建会话并命名
  
  tmux ls #查看后台会话
  tmux a #连接会话(a或者attatch) 默认连接到最近一个创建的会话
  tmux a -t xxx #xx为会话编号  连接到指定会话
  ```

- 将当前会话放入后台 <kbd>Ctrl</kbd><kbd>b</kbd>  <kbd>d</kbd> 

- 创建会话 放入后台 并向其发送要执行的指令

  ```shell
  session=test
  window=main
  command='whoami'
  
  tmux new -s $session -n $window -d #创建会话test 窗口名为main 后台运行
  tmux send-keys -t $session:$window "$command" C-m
  
  #其他相关命令
  #tmux split-window -v -t $session  #水平分割 -h 垂直分割
  #tmux select-layout -t $session main-horizontal  #分割模式
  #tmux attach -t $session  #连接到会话查看
  ```

  

