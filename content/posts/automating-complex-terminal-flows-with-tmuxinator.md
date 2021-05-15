---
title: "Automating Complex Terminal Flows With Tmuxinator"
date: 2020-08-30T13:27:10-04:00
draft: false
featured_image: "https://i.imgur.com/CTOrhcX.jpg"
---
**This post originally appeared on** [Dev.to](https://dev.to/bigj1m/automating-multiple-terminals-with-tmux-and-tmuxinator-47n2)

<span>Photo by <a href="https://unsplash.com/@_imkiran?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Sai Kiran Anagani</a> on <a href="https://unsplash.com/s/photos/automation?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></span>

I was working on a big e-commerce project that involved at least 5 terminals, each requiring few to several commands. Spinning up the back and front end, the database and the local environments required to remember a considerable amount of commands in a precise order and takes between 2 and 3 minutes to complete. Seems not like a lot but if I do it once per day, five days a week for 50 weeks: that's ~8 hours of manual work. I thought about using some bash scripting and that's when I discovered tmux and tmuxinator.

## tmux

[tmux](https://github.com/tmux/tmux/wiki) stands for Terminal Multiplexer. It lets you switch between several programs inside one terminal, detach and reattach them to a different terminal at will. It will work with multiple programs and shells in one terminal, like a windows manager. tmux protects your remote connections if installed on a remote server. It's ideal for SSH, PuTTy and other connections. Programs can be remotely accessed by many local computers.

Let's install it first.

```bash
# Ubuntu and Debian based distros
sudo apt install tmux

# CentOS and Fedora
sudo yum install tmux

# macOS
brew install tmux
```

## tmuxinator

tmux is a great and powerful tool that can save a lot of trouble, but everything is still manual. Fortunately, tmux is wonderfully automatable and that's where tmuxinator shines.

[tmuxinator](https://github.com/tmuxinator/tmuxinator) is a tool to automate the creation of sessions with tmux. We create a new project, which opens up a YAML file. In this file, we specify how many windows and panes we want and their layouts. There is many hooks to run commands at certain moments of the tmux run: when a project start, when it stops, etc.

tmux executes any command as if you typed it. It waits for a command to finish before launching the next. This is perfect for waiting on an SSH connection to run your next commands.

Let's install it:

```bash
# Ubuntu and Debian based distros
sudo apt-get install tmuxinator

# Fedora
gem install tmuxinator

# macOS
brew install tmuxinator
```

I highly recommand setting up an aliases for tmuxinator so you don't have to write the whole name for every command.


```bash
# .bashrc/.zshrc/.*rc
alias tmuxinator="mux"
```

To create a new tmuxinator project we use the new command

```bash
tmuxinator new MyProject
```

Every tmuxinator command can be abbreviated to a single letter. With our alias the command is simply

```bash
mux n MyProject
```

This creates a yaml file where we put all our flow to be automated. I recommend doing the manual setting up of your project in real time while you edit the yaml file to make things easier and to not forget a step. 

Let's have a look at the actual project I'm using for my local dev env:

```yaml 
name: myproject
root: ~/

startup_window: vagrant and docker-git

startup_pane: 1

# The first level is the list of windows. 
windows:
  # Second level is each window name. Each element use a -

  # Commands can be specified inline 
  - ide: /usr/local/pycharm-2020.1.3/bin/pycharm.sh 
                                                    
  - watchers:
      # 3rd level is the window options
      # layout option is how the panes appear in a windows
      layout: even-horizontal                             
           
      # List of panes inside a window. Each is named              
      panes:                  
        - vendor watcher:
          # 4th level is a list of commands to execute
          - j myproject-app         
          - clear
          - npm run watch:vendor
        - customer watcher:
          - j myproject-app         # zsh jump plugin
          - clear             
          - npm run watch:customer
  - vagrant and docker-git:
      layout: even-vertical
      panes:
        - vagrant:
          - j MyProjectFiles
          - clear
          - workon MyProject
          - vagrant up
          # this command takes time and tmuxinator 
          # waits before executing the next one
          - vagrant ssh      
          - source /usr/local/virtualenvs/myproject374/bin/activate
          - cd /srv/myproject-api
          - export $(cat .env | xargs)
          - sudo service supervisor restart
          - clear
        - docker:
          - j myproject
          - clear
          - docker stop myproject_mysql
          - docker rm myproject_mysql
          - docker run --name myproject_mysql -e MYSQL_ALLOW_EMPTY_PASSWORD=true -p 3306:3306 -d mysql:5.6.35
          - clear
          - docker ps

```

We then start this automation with the command

```bash
tmuxinator start MyProject

# or 
mux s MyProject
```

We can edit the file with

```bash
tmuxinator edit MyProject

# or 
mux e MyProject
```

When starting the project, everything kicks in at the same time in a matter of seconds. The only thing that takes time is waiting for the VMs to be created, but since everything runs in parallel, we can already start to code in the IDE. We went from 2-3 minutes to 10 seconds, that's a huge gain!

## Let's dive into the details of tmux

### tmux Server and client

tmux keeps all its states in one single main process called a tmux server. It runs in the backgroup, manages all the programs and keep track of their outputs. It launches automagically when a tmux command is used and stops by itself when there is no program left to run. 

When a user starts a tmux client, it takes over his terminal and attach to the server so they can talk via a socket file in `/tmp`.

### Pane

Inside tmux, every terminal belongs to a pane, that is a rectangular area much like a tile in a windows manager. You can navigate between panes with `ctrl+b ←/↑/↓/→`, split panes vertically with `ctrl+b %` and horizontally with `ctrl+b %`. 

### Window

Every pane is contained inside a window, which is the whole area of the terminal. There can be many window per session. These windows can be reordered and have a name. You can switch from a window to another either with its number `ctrl+b <0-9>` or `ctrl+b n` and `ctrl+b p` for next and previous. Windows have a layout which is how each panes appear inside a window. In a layout, panes are seperated by a line called a pane border. You can either use one of the 4 preset layouts or specify your own.

### Status bar
At the bottom of the terminal, there is a status bar. It indicates which session, pane and window is currently active.

### Session
One or many windows are in a session. Each session window has a numbered index and a name, at the bottom in the status bar. A window can be part, or attached, to many sessions. A session can be attached to one or more clients and has a unique name.

### Commands
Inside tmuxinator, we can execute commands such as switching window or pane, close session or open new one. To get into command mode, use `ctrl+b` then the command. When entering a semicolon, you can enter commands much like the vi/vim command mode.

### Bonus: Here is a [tmux cheatsheet](https://tmuxcheatsheet.com/) that is super helpful to get into tmux and help tmuxinator scripting

