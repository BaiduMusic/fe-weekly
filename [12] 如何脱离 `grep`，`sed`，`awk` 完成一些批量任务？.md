# 如何脱离 `grep`，`sed`，`awk` 完成一些批量任务？

首先要提下 python 的 `-c` 选项，比如打印 `10`：`python -c 'print 10'` 。即使不用 -c 选项，用 pipe 也是可以的，如 `echo 'print 10' | python`。这种用法非常标准，ruby，lua，node 之类的一般解释器都支持。ruby 甚至支持 `-n` 和 `-p` 这种便利的选项。

除此之外你还可以用 `cat | python`，输入完成后 `enter, ctrl-D` 结束输入。这样做的好处是可以随意打回车或者引号了。

如果你会 vim，可以开空 vim，然后 insert 模式下输入 `print 10`，然后命令模式下输入 `:w !python` 结束输入。用 vim 的好处是有语法高亮等高级功能而不产生临时文件。

## Ruby

这里先讲 ruby 因为 mac 自带 ruby，它原 [生字符串处理库][string] 很强大，而且有便利的撇号 ["`" 和 "%x"][subshell]，感兴趣的话可以看看文档，即使你不懂 ruby 也会觉得这些让它非常适合处理 cli 任务。

[string]: http://www.ruby-doc.org/core-2.2.0/String.html
[subshell]: http://ruby-doc.org/core-2.2.0/Kernel.html#method-i-60

为了便于输入，系统里加了几个 alias：

```shell
alias r_init="ruby -e 'require \"FileUtils\"; F, D = FileUtils, Dir'"
alias r="r_init -e"
alias rp="r_init -p -e"
```

0. **打印第一个含有数字的文件名**

    bash: ```ls -1 | grep -m 1 -e '.*[0-9].*'```

    ruby： ```r 'puts `ls`[/.*\d.*/]'``` _(少打 9 字符)_

0. **替换所有文件名中的 y 为 30 个 `o`**

    bash: ```ls -1 | sed s/y/oooooooooooooooooooooooooooooo/```

    ruby: ```ls -1 | rp '$_.gsub! /y/, "o" * 30'``` _(少打打 12 字符)_

    你还可以继续把这个命令 pipe 下去。

0. **批量重命名文件为 “[3 字宽 0 补齐递增]” + “原文件名” 的形式**

    bash: 这个 sed 我不好好查查文档也写不出 ;P

    ruby: ```r 'D["*"].each_with_index { |f, i| F.mv f, "[%03d]" % i + f }'```

    操作类似如下命令：

    ```shell
    mv \"a\".txt \[001\]\"a\".txt
    mv a\ b.txt \[002\]a\ b.txt
    ```

    文件名中可能有引号或空格，使用 sed 拼接 mv 命令时需注意转义，而这里 ruby 调用的原生方法，所以无需转义即是安全的。

    不借助三方库，其他语言很难写的如此之短，且易于理解和记忆。

## Node & Coffee

node 本身的库很基础，不足以完成日常所需，但是它的三方库往往是最容易使用和获取的。**正是如此，用之前准备工作要更多**。

由于没有主流系统自带 node，你需要先安装它，然后配置系统环境，这个步骤必不可少。
执行 ```echo `npm config get prefix`/lib/node_modules```，将获得的结果设置到环境变量 `NODE_PATH` 中，当然你不担心 npm 龟速的话，也可以直接把如下代码加入到你的 bashrc 之类的文件里：

```
export NODE_PATH=`npm config get prefix`/lib/node_modules
```

有了这个环境变量后我们才可以 require 全局安装的三方库。然后我们再添加个 shell 函数：

```shell
c() {
    coffee -e '
require "shelljs/global"
F = require "fs"
puts = (args...) -> console.log args
$1'
}
```

然后我们就可以安装一些三方库来测试下效果了，比如执行 `npm i shelljs` 安装好三方库，然后执行 `c 'puts ls "*"'`，如果正常打印了，当前目录的文件就基本配置完毕了。

在 require 一堆三方库之后 node 的解决实际问题的能力会非常强大，V8 的爆发处理能力虽然吃内存，但很多下情况会比 ruby 或者 python 快很多，异步 IO 也会在处理慢移动磁盘时很便利。

这里只提一个常见的问题，关于 coffee 的单行代码怎么写的问题。这个问题上 coffe 和 python 最大的不同在于多了一个 `then` 关键字：

- `c 'for i in [1..10] then puts i'`
- `c `try F.readFileSync 'a.txt'; catch err then puts err'`

当然，由于 js 是最 buggy 的 duck typing 语言之一, 外加大部分的功能和库都是能用 chain 范式完成功能的，one line code 非常容易写。

**如果你是个三方库控的前端人员，且不畏惧 js 的种种 buggy 问题，node 会是不二选择。**

## Perl & PHP

当前 2015 年初，perl + php 这方面的处理库实际上比 node 要多很多。而且 perl 或者 php 解释器大部分系统自带，生态环境非常无解的强大。
除了语法相对于后来的语言来说有些不简练，找不到什么不选它的理由。perl 我也不多写例子了，官方教程 hello world 之后都不是教你 for 循环之类的，直接就上文件 IO 操作，由此可见一斑。

如果如果习惯了用 shell，并且觉得在沙漠中寻找绿洲才是王道，perl 在等你。

## Python

这些年的使用经验告诉我，它比较适合对 python 知根知底的人，初学者想用它玩弄文件系统会碰到各种问题，首先把[多个命令写到一行][one-line-python]就会有很多问题。再比如 python2 和 python3 的一些问题，文件名编码的问题等。

由于本人学识尚浅，这里就不在各位看官面前班门弄斧举 python 的例子了。

**如果你是个爬行动物爱好者，并且觉得你之前学的 python 技能能无坚不摧，请选择 python。**

[one-line-python]: http://stackoverflow.com/questions/6167127/how-to-put-multiple-statements-in-one-line

## Others

Go，Haskell 之类的静态类型编译语言都不在讨论范围内。

## 总结

当然上述方法对我来说可能有些过时了，现在处理一些难以复用的任务都是用 sublime 或 vim 可视化（非编程）完成。由于具体步骤太直观可视化，这里难以用文字描述，就不赘述了，有机会的话可以录视屏演示下。

常复用的也不会用命令行敲了，太浪费生命，直接写成库或者 snippet 存在 gist 之类的地方。此外需要高性能的时候也不会不停的在 shell 里 loop 调用类似 mv, cp 之类的程序，而是直接写 C 之类的调用内核方法。

写这么多不是想说你应该学会 ruby 什么的，每个工具都有它适用的场景：

> **我们往往最需要的可能是锻炼想象力，而不是评判什么工具最好，否则我们的记忆力永远不够用。**