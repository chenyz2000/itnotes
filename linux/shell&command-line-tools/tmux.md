# 基本使用

- 创建会话

  ```shell
  tmux #自动创建会话，按数字依次命名
  tmux new -s <session-name>  #创建会话并命名
  
  tmux ls #查看后台会话
  tmux a #连接会话(a或者attatch) 默认连接到最近一个创建的会话
  tmux a -t xxx #xx为会话编号  连接到指定会话
  ```

- 将当前会话放入后台 <kbd>Ctrl</kbd><kbd>b</kbd>  <kbd>d</kbd> 

- 列出所有会话

  ```shell
  tmux ls
  ```

- 关闭会话

  从会话中退出即会关闭会话。

  使用命令关闭：

  ```shell
  tmux kill-session  #关闭最近的一个会话
  tmux kill-session -t <session-name>  #关闭指定会话
  tmux kill-server  #关闭所有会话
  ```

# 常用快捷键

前缀 <kbd>Ctrl</kbd><kbd>b</kbd> 

- w 窗口
- s 会话



# 非交互式操作

- 创建会话 放入后台 并向其发送要执行的指令

  ```shell
  session=test
  window=main
  command='whoami'
  
  #创建会话test后台运行
  tmux new -s $session -d
  #可以在会话中创建窗口 例如窗口名为main
  #tmux new -s $session -n $window -d
  
  #向回话发送指令
  tmux send-keys -t $session "$command" C-m
  #可以指定发送某个窗口
#tmux send-keys -t $session:$window "$command" C-m
  ```
  
  其他：
  
  ```shell
  #分割指定会话的窗口（不指定窗口时使用每个会话默认的窗口）
  tmux split-window -v -t $session  #-v水平分割 -h 垂直分割
  
  tmux select-layout -t $session main-horizontal  #分割模式
  ```
  
  

