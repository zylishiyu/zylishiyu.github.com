---
layout: post
title: "线程alarm"
description: ""
category: 
tags: [alarm]
---
{% include JB/setup %}

在使用mysql的过程中，发现mysql不支持ms级超时，想在上层应用来做。由于我们的程序是多线程，因此想开发一个多线程安全的alarm做超时控制。研究了一下mysql库的做法，总结出2种方法来实现。

## alarm thread + worker threads

此方案主要有alarm thread和worker threads两类线程组成。Alarm thread维护和管理所有的超时设置，给超时时间到了的worker thread发送SIGALRM信号。Worker thread将超时时间注册到最小堆中，如果比堆顶的时间还早，则发送SIGALRM信号给alarm thread更新其sleep时间。设置SIGALARM的handler函数为空，SIGALRM的作用是将对方从系统调用中唤醒继续执行。

Worker thread一次执行的具体流程如下：Worker thread开始执行，将超时时间加入到最小堆中，如果比堆顶元素小，则给alarm thread发SIGALRM信号，alarm thread从sleep（具体sleep机制使用pthread_cond_timedwait实现）中被唤醒，重新设置sleep时间并进入sleep状态。Worker thread执行和数据库交互的语句。如果执行时间过长，超过设定的超时间，会导致alarm thread从sleep返回，然后查看此worker thread的超时时间到了，则给此worker thread发送SIGALRM信号，中断worker thread和数据库的交互。Worker thread将超时设置从堆中删除，继续执行后续的业务处理。

## main thread + worker threads

此方案主要有main thread和worker threads两类线程。Main thread设置SIGALRM的handler为process_alarm，同时维护一个超时设置的最小堆，启动worker threads。其中process_alarm和worker thread的流程如上图所示。

Worker thread一次执行的具体流程如下：Worker thread开始执行，将超时时间加入到最小堆中，如果比堆顶元素小，则给main thread发SIGALRM信号，使其调用process_alarm函数更新alarm时间。然后执行和数据库交互的语句。如果执行时间过长，会导致process_alarm设置的alarm发出SIGALRM信号，进入SIGALRM的handler即process_alarm中，发现有超时的thread，则给对应的worker thread发SIGALRM信号，中断worker thread和数据库的交互，worker thread将超时从堆中删除，然后继续执行后续的业务处理。

