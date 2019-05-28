# suppression
valgrind这个特性是为了屏蔽不必要的error报错，由于valgrind是针对每个指令的监控，所以当每一条指令出现错误时都会相应的报错，而有一些错误是存在于系统lib库中的，而不是作为我们的代码中存在的，这些错误我们是不care的，但是每次执行都会报出来，这样很不好看，因此valgrind提供这个suppression的特性用来忽略某些报错。

默认情况下我们在安装valgrind时也会安装对应的supp文件：/usr/lib/valgrind/default.supp，每次在valgrind运行时都会去读取该文件，除非命令行指定：--default-suppressions=no。除了支持默认配置外，valgrind还可以通过命令行传入suppression文件支持扩展多个suppression文件。
```
valgrind --suppressions=path/to/suppression.supp
```
既然可以扩展，那么下一个问题就来了，如何进行扩展，suppression文件的语法格式是怎样的呢？这个语法问题笔者建议直接去看user manual，这里只介绍一种快捷的方式，可以通过指定命令行参数：
```
--gen-suppressions=yes
```
来打印报出的每个错误对应的忽略语法。这样只需要拷贝需要忽略的错误语法集中到一个suppression文件中，然后利用--suppressions选项传入，机会发现屏蔽已经成功。

