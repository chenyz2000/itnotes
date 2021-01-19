# 简介

mux 是一款终端复用命令行工具，一般用于 Terminal 的窗口管理，可实现主多会话多窗口，放置任务后台执行等功能。

tmux基本概念：

- 会话 session   创建一个新的独立的shell环境（非当前shell的子shell）
- 窗口 window  每个会话至少一个窗口
- 窗格 panes   每个窗口可以切分成多个窗格



# 基本使用

## 会话操作

- 创建会话

  ```shell
  tmux #自动创建会话，按数字依次命名
  tmux new -s <session-name>  #创建会话并命名
  ```

  

- 将当前会话放入后台 <kbd>Ctrl</kbd><kbd>b</kbd>  <kbd>d</kbd> 



- 查看会话列表和连接到会话

  ```shell
  tmux ls        #查看后台会话
  tmux a         #连接会话(a或者attatch) 默认连接到最近一个创建的会话
  tmux a -t xxx  #xx为会话编号  连接到指定会话
  ```



- 关闭会话

  从会话的shell中退出即会关闭会话。（例如执行`exit`或者按下<kbd>Ctrl</kbd> <kbd>d</kbd>）

  可以使用命令关闭后台会话：

  ```shell
  tmux kill-session  #关闭最近的一个会话
  tmux kill-session -t <session-name>  #关闭指定会话
  tmux kill-server   #关闭所有会话
  ```



- 快捷键：

  按下tmux的快捷键前缀按键 <kbd>Ctrl</kbd><kbd>b</kbd> （Mac为<kbd>control</kbd><kbd>c</kbd>，再按其他按键：
  - `$` 重命名当前会话

  - `s`  选择会话列表

  - `d` detach 当前会话，运行后将会退出 tmux 进程，返回至 shell 主进程

    

## 窗口操作

按下tmux的快捷键前缀按键 <kbd>Ctrl</kbd><kbd>b</kbd> （Mac为<kbd>control</kbd><kbd>c</kbd>，再按其他按键：

- `w` 窗口列表选择，注意 macOS 下使用 `⌃p` 和 `⌃n` 进行上下选择
- `c` 新建窗口，此时当前窗口会切换至新窗口，不影响原有窗口的状态
- `p` 切换至上一窗口
- `n` 切换至下一窗口
- `&` 关闭当前窗口
- `,` 重命名窗口，可以使用中文，重命名后能在 tmux 状态栏更快速的识别窗口 id
- `0` 切换至 0 号窗口，使用其他数字 id 切换至对应窗口
- `f` 根据窗口名搜索选择窗口，可模糊匹配



## 窗格操作

按下tmux的快捷键前缀按键 <kbd>Ctrl</kbd><kbd>b</kbd> （Mac为<kbd>control</kbd><kbd>c</kbd>，再按其他按键：

- `q` 显示所有窗格的序号，在序号出现期间按下对应的数字，即可跳转至对应的窗格
- `%` 左右平分出两个窗格
- `"` 上下平分出两个窗格
- `x` 关闭当前窗格
- `{` 当前窗格前移
- `}` 当前窗格后移
- `;` 选择上次使用的窗格
- `o` 选择下一个窗格，也可以使用上下左右方向键来选择
- `space` 切换窗格布局，tmux 内置了五种窗格布局，也可以通过 `⌥1` 至 `⌥5`来切换
- `z` 最大化当前窗格，再次执行可恢复原来大小



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
  
  

# 常用配置

tmux用户配置文件为`~/.tmux.conf`

```shell
# 开启鼠标模式
set -g mode-mouse on

# 允许鼠标选择窗格
set -g mouse-select-pane on

# 如果喜欢给窗口自定义命名，那么需要关闭窗口的自动命名
#set-option -g allow-rename off

# 如果对 vim 比较熟悉，可以将 copy mode 的快捷键换成 vi 模式
#set-window-option -g mode-keys vi
```

配置文件修改完成后，执行 `tmux kill-server` 重启所有 tmux 进程，或者在 tmux 会话中使用 `⌃b` `:` 进入控制台模式，输入 `source-file ~/.tmux.conf` 命令重新加载配置。