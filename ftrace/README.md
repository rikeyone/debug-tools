# ftrace在实际问题中的应用

我在自己的其他博文中有介绍ftrace的介绍和使用方法，那么在实际的工作中，ftrace可以用来做什么呢？
在实际问题场景中ftrace主要用来跟踪延时和调用流程，分析性能问题。

## function/function_graph　分析内核函数调用流程
function/function_graph是利用的GCC的编译选项来完成对函数的插桩的，
ftrace自带的function tracer和function_graph这两个tracer内核预定义的连个tracer，一般我们很少用他们去debug具体的性能问题，但是可以用来分析内核函数调用流程的。
function tracer使用如下：
```
echo function > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on

#test work

echo 0 > /sys/kernel/debug/tracing/tracing_on

cat /sys/kernel/debug/tracing/trace
```

结果如下：
```
# tracer: function
#
# entries-in-buffer/entries-written: 261028/11606988   #P:8
#
#                              _-----=> irqs-off
#                             / _----=> need-resched
#                            | / _---=> hardirq/softirq
#                            || / _--=> preempt-depth
#                            ||| /     delay
#           TASK-PID   CPU#  ||||    TIMESTAMP  FUNCTION
#              | |       |   ||||       |         |
          <idle>-0     [006] dn.2 20756.326744: post_ttbr_update_workaround <-__cpu_suspend_exit
          <idle>-0     [006] dn.2 20756.326747: uao_thread_switch <-__cpu_suspend_exit
          <idle>-0     [006] dn.2 20756.326748: hw_breakpoint_reset <-__cpu_suspend_exit
          <idle>-0     [006] dn.2 20756.326749: write_wb_reg <-hw_breakpoint_reset
          <idle>-0     [006] dn.2 20756.326749: write_wb_reg <-hw_breakpoint_reset
          <idle>-0     [006] dn.2 20756.326750: write_wb_reg <-hw_breakpoint_reset
          <idle>-0     [006] dn.2 20756.326750: write_wb_reg <-hw_breakpoint_reset
          <idle>-0     [006] dn.2 20756.326751: write_wb_reg <-hw_breakpoint_reset
          <idle>-0     [006] dn.2 20756.326751: write_wb_reg <-hw_breakpoint_reset
          <idle>-0     [006] dn.2 20756.326752: write_wb_reg <-hw_breakpoint_reset
          <idle>-0     [006] dn.2 20756.326752: write_wb_reg <-hw_breakpoint_reset
[...]
```
function_graph tracer的使用说明如下：
```
echo function_graph > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/tracing_on

#test work

echo 0 > /sys/kernel/debug/tracing/tracing_on

cat /sys/kernel/debug/tracing/trace
```

结果如下：
```
# tracer: function_graph
#
# CPU  DURATION                  FUNCTION CALLS
# |     |   |                     |   |   |   |
 6)               |      finish_task_switch() {
 6)               |        _raw_spin_unlock_irq() {
 6)   0.052 us    |          do_raw_spin_unlock();
 6)   0.104 us    |          preempt_count_sub();
 6)   2.240 us    |        }
 6)   3.542 us    |      }
 6)   0.156 us    |      preempt_count_sub();
 6)               |      _raw_spin_lock_irq() {
 6)   0.364 us    |        preempt_count_add();
 6)   0.052 us    |        do_raw_spin_lock();
 6)   2.656 us    |      }
 6)               |      process_one_work() {
 6)   0.260 us    |        find_worker_executing_work();
 6)               |        _raw_spin_lock_irqsave() {
 6)   0.104 us    |          preempt_count_add();
 6)   0.052 us    |          do_raw_spin_lock();
 6)   1.406 us    |        }
 6)               |        _raw_spin_unlock_irqrestore() {
 6)   0.052 us    |          do_raw_spin_unlock();
 6)   0.052 us    |          preempt_count_sub();
 6)   1.823 us    |        }
 6)   0.053 us    |        set_work_pool_and_clear_pending();
 6)               |        _raw_spin_unlock_irq() {
 6)   0.104 us    |          do_raw_spin_unlock();
 6)   0.156 us    |          preempt_count_sub();
 6)   1.979 us    |        }

[...]
```
上面介绍的两者方式都可以用来查看代码运行流程，但是这两个tracer默认都是跟踪所有的函数，这对于内核来说是一个庞大的性能消耗，因此实际使用时很少会直接这么使用，内核支持使用dynamic ftrace插桩，针对每个函数可以通过debugfs节点选择是否要使能它。如果我们想只跟踪特定函数，可以把需要配置跟踪的函数写入到节点：
```
/sys/kernel/debug/tracing/set_ftrace_filter ------- function tracer
/sys/kernel/debug/tracing/set_graph_function ------ function_graph tracer
```
或者想把一些函数排除在外，可以写入如下节点：
```
/sys/kernel/debug/tracing/set_ftrace_notrace ------- function tracer
/sys/kernel/debug/tracing/set_graph_notrace ------ function_graph tracer
```
比如我们想要跟踪scheduler_tick函数的运行流程，可以使用如下方式：
```
echo function_graph > /sys/kernel/debug/tracing/current_tracer
echo scheduler_tick > /sys/kernel/debug/tracing/set_graph_function
echo 1 > /sys/kernel/debug/tracing/tracing_on

#test work

echo 0 > /sys/kernel/debug/tracing/tracing_on

cat /sys/kernel/debug/tracing/trace
```
抓出来的trace数据如下：
```
3)               |  scheduler_tick() {
3)               |    _raw_spin_lock() {
3)   0.313 us    |      preempt_count_add();
3)   0.260 us    |      do_raw_spin_lock();
3)   5.572 us    |    }
3)   0.261 us    |    set_window_start();
3)               |    sched_ktime_clock() {
3)               |      ktime_get() {
3)   0.261 us    |        arch_counter_read();
3)   2.604 us    |      }
3)   5.417 us    |    }
3)               |    update_task_ravg() {
3)               |      clk_osm_get_cpu_cycle_counter(
3)   0.208 us    |        logical_cpu_to_clk();
3)   0.208 us    |        clk_hw_get_parent();
3)               |        _raw_spin_lock_irqsave() {
3)   0.208 us    |          preempt_count_add();
3)   0.260 us    |          do_raw_spin_lock();
3)   3.959 us    |        }
[...]

```

这一段log将只会包含scheduler_tick函数对应的内容，其中还会打印出每个函数消耗的时间，这个时间是包含了sleep time的，所以可以用来定位系统延迟发生在哪个函数中。
这样看这个log很长，也很难分析，可以采用一个vim插件来尝试优化这个问题。
```
" Enable folding for ftrace function_graph traces.
"
" To use, :source this file while viewing a function_graph trace, or use vim's
" -S option to load from the command-line together with a trace.  You can then
" use the usual vim fold commands, such as "za", to open and close nested
" functions.  While closed, a fold will show the total time taken for a call,
" as would normally appear on the line with the closing brace.  Folded
" functions will not include finish_task_switch(), so folding should remain
" relatively sane even through a context switch.
"
" Note that this will almost certainly only work well with a
" single-CPU trace (e.g. trace-cmd report --cpu 1).

function! FunctionGraphFoldExpr(lnum)
  let line = getline(a:lnum)
  if line[-1:] == '{'
    if line =~ 'finish_task_switch() {$'
      return '>1'
    endif
    return 'a1'
  elseif line[-1:] == '}'
    return 's1'
  else
    return '='
  endif
endfunction

function! FunctionGraphFoldText()
  let s = split(getline(v:foldstart), '|', 1)
  if getline(v:foldend+1) =~ 'finish_task_switch() {$'
    let s[2] = ' task switch  '
  else
    let e = split(getline(v:foldend), '|', 1)
    let s[2] = e[2]
  endif
  return join(s, '|')
endfunction

setlocal foldexpr=FunctionGraphFoldExpr(v:lnum)
setlocal foldtext=FunctionGraphFoldText()
setlocal foldcolumn=12
setlocal foldmethod=expr
                                                                                                      
```
把它保存为function-graph-fold.vim，使用如下命令打开trace文件：
```
vim -S function-graph-fold.vim trace
```
这一段vim配置可以让function trace进行折叠，利用za可以展开折叠。
```
-              502  3)               |  scheduler_tick() {
|+             503  3)               |    _raw_spin_lock() {---------------------------------
|              507  3)   0.468 us    |    set_window_start();
|+             508  3)               |    sched_ktime_clock() {------------------------------
|+             513  3)               |    update_task_ravg() {-------------------------------
|              534  3)   0.625 us    |    update_rq_clock();
|+             535  3)               |    task_tick_fair() {---------------------------------
|+             561  3)               |    cpu_load_update_active() {-------------------------
|              571  3)   0.521 us    |    calc_global_load_tick();
|              572  3)   0.521 us    |    early_detection_notify();
|+             573  3)               |    _raw_spin_unlock() {-------------------------------
|              577  3)   0.417 us    |    idle_cpu();
|+             578  3)               |    trigger_load_balance() {---------------------------
|              586  3)   0.364 us    |    __rcu_read_lock();
|              587  3)   0.521 us    |    update_preferred_cluster();
|              588  3)   0.417 us    |    __rcu_read_unlock();
|              589  3)   0.573 us    |    check_for_migration();
|              590  3) ! 298.594 us  |  } 

```
## event trace/trace point 分析子系统latency
event trace是进行性能分析时最常用的功能，它虽然是ftrace的一部分，但是和上面提到的function trace是不一样的，它只是利用了ftrace框架的ring buffer和debugfs来实现的。它的关键是tracepoint，插桩并不是利用的gcc的编译选项来做的，而是在代码中需要插桩的位置，开发者自行实现的tracepoint。
我们可以通过如下方式跟踪event或者叫tracepoint：
```
echo nop > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/events/enable
```
这会默认跟踪内核中所有的tracepoint，打印很多信息,一般很少会这么用，我们会指定特定的一个或者几个tracepoint进行trace操作，系统中存在的所有tracepoint可以通过

	cat /sys/kernel/debug/tracing/available_events

进行查看，举例比如：
```
echo 0 > /sys/kernel/debug/tracing/trace 		## clear trace buffer
echo nop > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/events/enable
echo i2c:i2c_write > /sys/kernel/debug/tracing/set_event
echo 1 > /sys/kernel/debug/tracing/tracing_on

#test work

echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace
```
抓取得结果如下：
```
#
# entries-in-buffer/entries-written: 86/86   #P:8
#
#                              _-----=> irqs-off
#                             / _----=> need-resched
#                            | / _---=> hardirq/softirq
#                            || / _--=> preempt-depth
#                            ||| /     delay
#           TASK-PID   CPU#  ||||    TIMESTAMP  FUNCTION
#              | |       |   ||||       |         |
     kworker/0:0-9794  [000] .... 28497.642973: i2c_write: i2c-0 #0 a=00c f=0000 l=3 [10-70-c8]
    Binder:865_A-3050  [000] .... 28497.667486: i2c_write: i2c-5 #0 a=026 f=0000 l=2 [1e-01]
    Binder:865_A-3050  [000] .... 28497.684999: i2c_write: i2c-5 #0 a=026 f=0000 l=2 [1e-01]
    Binder:865_A-3050  [002] .... 28497.705814: i2c_write: i2c-5 #0 a=026 f=0000 l=2 [1e-01]
    Binder:865_A-3050  [000] .... 28497.725763: i2c_write: i2c-5 #0 a=026 f=0000 l=2 [07-01]
   kworker/u16:0-6     [002] .... 28497.781856: i2c_write: i2c-5 #0 a=026 f=0000 l=2 [07-00]
 nfc@1.1-service-3257  [001] .... 28497.812347: i2c_write: i2c-2 #0 a=028 f=0000 l=4 [21-06-01-00]
   kworker/u16:0-6     [002] .... 28497.814925: i2c_write: i2c-5 #0 a=026 f=0000 l=1 [00]

[...]
```
各个子系统tracepoint的结果是各不相同的，是可以自定义print format的，那么抓出如上的数据，要如何分析呢？可以通过查看如下节点来看print的内容表示什么含义，比如本例：
```
cat /sys/kernel/debug/tracing/events/i2c/i2c_write/format
name: i2c_write
ID: 805
format:
	field:unsigned short common_type;	offset:0;	size:2;	signed:0;
	field:unsigned char common_flags;	offset:2;	size:1;	signed:0;
	field:unsigned char common_preempt_count;	offset:3;	size:1;	signed:0;
	field:int common_pid;	offset:4;	size:4;	signed:1;

	field:int adapter_nr;	offset:8;	size:4;	signed:1;
	field:__u16 msg_nr;	offset:12;	size:2;	signed:0;
	field:__u16 addr;	offset:14;	size:2;	signed:0;
	field:__u16 flags;	offset:16;	size:2;	signed:0;
	field:__u16 len;	offset:18;	size:2;	signed:0;
	field:__data_loc __u8[] buf;	offset:20;	size:4;	signed:0;

print fmt: "i2c-%d #%u a=%03x f=%04x l=%u [%*phD]", REC->adapter_nr, REC->msg_nr, REC->addr, REC->flags, REC->len, REC->len, __get_dynamic_array(buf)

```

由于这个event trace在日常工作中是非常关键的功能，我再举一个例子，比如遇到io导致的延迟问题，那么可以利用block:block_rq_insert这个tracepoint去跟踪io的情况：
```
echo 0 > /sys/kernel/debug/tracing/trace 		## clear trace buffer
echo nop > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/events/enable
echo block:block_rq_insert > /sys/kernel/debug/tracing/set_event
echo 1 > /sys/kernel/debug/tracing/tracing_on

#test work

echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace
```
运行结果如下：
```
# tracer: nop
#
# entries-in-buffer/entries-written: 26/26   #P:8
#
#                              _-----=> irqs-off
#                             / _----=> need-resched
#                            | / _---=> hardirq/softirq
#                            || / _--=> preempt-depth
#                            ||| /     delay
#           TASK-PID   CPU#  ||||    TIMESTAMP  FUNCTION
#              | |       |   ||||       |         |
     kworker/3:0-9167  [003] d..1 29854.965993: block_rq_insert: 0,0 N 0 () 0 + 0 [kworker/3:0]
     kworker/3:0-9167  [003] d..1 29854.966260: block_rq_insert: 0,0 N 0 () 0 + 0 [kworker/3:0]
    kworker/3:1H-347   [003] d..1 29854.966367: block_rq_insert: 0,0 N 0 () 0 + 0 [kworker/3:1H]
     kworker/3:0-9167  [003] d..1 29854.969788: block_rq_insert: 0,0 N 0 () 0 + 0 [kworker/3:0]
 SettingsProvide-1641  [006] d..1 29855.789272: block_rq_insert: 8,0 WS 20480 () 116198528 + 40 [SettingsProvide]
     kworker/6:2-6717  [006] d..1 29855.794193: block_rq_insert: 0,0 N 0 () 0 + 0 [kworker/6:2]
     jbd2/dm-0-8-631   [002] d..1 29855.801276: block_rq_insert: 8,0 WS 53248 () 32244024 + 104 [jbd2/dm-0-8]
     jbd2/dm-0-8-631   [001] d..1 29855.804316: block_rq_insert: 8,0 FWS 0 () 0 + 0 [jbd2/dm-0-8]
     kworker/0:1-9897  [000] d..1 29855.805400: block_rq_insert: 8,0 WFS 4096 () 32244128 + 8 [kworker/0:1]
   kworker/u16:3-8416  [001] d..1 29856.410411: block_rq_insert: 8,0 WM 4096 () 15194696 + 8 [kworker/u16:3]
   kworker/u16:3-8416  [001] d..1 29856.410470: block_rq_insert: 8,0 WM 8192 () 15469120 + 16 [kworker/u16:3]
   kworker/u16:3-8416  [001] d..1 29856.410481: block_rq_insert: 8,0 WM 4096 () 44554824 + 8 [kworker/u16:3]
   kworker/u16:3-8416  [001] d..1 29856.410487: block_rq_insert: 8,0 WM 4096 () 44555368 + 8 [kworker/u16:3]
   kworker/u16:3-8416  [001] d..1 29856.410493: block_rq_insert: 8,0 WM 4096 () 115857992 + 8 [kworker/u16:3]
   kworker/u16:3-8416  [001] d..1 29856.410498: block_rq_insert: 8,0 WM 4096 () 115858544 + 8 [kworker/u16:3]
[...]
```
更加详细的可以去跟踪一下调用栈：
```
echo 0 > /sys/kernel/debug/tracing/trace 		## clear trace buffer
echo nop > /sys/kernel/debug/tracing/current_tracer
echo 1 > /sys/kernel/debug/tracing/events/enable
echo block:block_rq_insert > /sys/kernel/debug/tracing/set_event
echo 1 > /sys/kernel/debug/tracing/options/stacktrace
echo 1 > /sys/kernel/debug/tracing/tracing_on
#test work
echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace
```
它的打印是这样的:
```
# tracer: nop
#
# entries-in-buffer/entries-written: 450/450   #P:8
#
#                              _-----=> irqs-off
#                             / _----=> need-resched
#                            | / _---=> hardirq/softirq
#                            || / _--=> preempt-depth
#                            ||| /     delay
#           TASK-PID   CPU#  ||||    TIMESTAMP  FUNCTION
#              | |       |   ||||       |         |
     kworker/0:0-9953  [000] d..1 30109.045297: block_rq_insert: 0,0 N 0 () 0 + 0 [kworker/0:0]
     kworker/0:0-9953  [000] d..1 30109.045320: <stack trace>
 => blk_execute_rq
 => scsi_execute
 => sd_sync_cache
 => sd_suspend_common
 => sd_suspend_runtime
 => scsi_runtime_suspend
 => __rpm_callback
 => rpm_callback
 => rpm_suspend
 => pm_runtime_work
 => process_one_work
 => worker_thread
 => kthread
 => ret_from_fork
     kworker/0:0-9953  [000] d..1 30109.045429: block_rq_insert: 0,0 N 0 () 0 + 0 [kworker/0:0]
     kworker/0:0-9953  [000] d..1 30109.045435: <stack trace>
 => blk_requeue_request
 => __scsi_queue_insert
 => scsi_queue_insert

```
此处我们也可以采用function graph去进一步查看某个函数调用信息：
```
echo 0 > /sys/kernel/debug/tracing/events/enable
echo 0 > /sys/kernel/debug/tracing/options/stacktrace
echo function_graph > /sys/kernel/debug/tracing/current_tracer
echo blk_requeue_request > /sys/kernel/debug/tracing/set_graph_function
echo 1000 > /sys/kernel/debug/tracing/tracing_thresh   ## latency threhold us
echo 1 > /sys/kernel/debug/tracing/options/funcgraph-duration
echo 1 > /sys/kernel/debug/tracing/options/funcgraph-abstime
echo 1 > /sys/kernel/debug/tracing/options/funcgraph-proc
echo 1 > /sys/kernel/debug/tracing/tracing_on
echo 0 > /sys/kernel/debug/tracing/tracing_on
cat /sys/kernel/debug/tracing/trace
```

设置latency threhold可以过滤掉很多低延时的函数：
```
# tracer: function_graph
#
#     TIME        CPU  TASK/PID         DURATION                  FUNCTION CALLS
#      |          |     |    |           |   |                     |   |   |   |
33224.935535 |   6)  kworker-6717  | $ 486047429 us |      } /* schedule */
33224.965690 |   6)  kworker-6717  | * 30072.18 us |      } /* schedule */
33225.047661 |   4)  kworker-399   | $ 1006941657 us |  } /* schedule */
33225.846533 |   6)  kworker-6717  | @ 880788.9 us |      } /* schedule */
33225.929458 |   6)  kworker-6717  | * 82793.12 us |      } /* schedule */
33234.967422 |   6)  kworker-6717  | $ 9037820 us  |      } /* schedule */
```
## ftrace应用层工具

上面的功能都是通过操作ftrace框架的接口来抓取trace数据的，那么实际上性能大神Brendan Gregg已经实现了一个应用层的perf-tools：https://github.com/brendangregg/perf-tools.git.
使用这个perf tools，可以快速的通过脚本完成上面所介绍的功能，并且比上面介绍的功能更加强大。
