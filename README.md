# gcc_clang

# A4

## Write-up 1

不同点：

1. `gcc` 和 `g++` 是 GNU Compiler Collection的一部分，主要用于编译 C 和 C++ 代码；`clang` 和 `clang++` 是 LLVM 项目的一部分，提供了一个替代 GCC 的编译器前端，主要用于编译 C、C++ 和 Objective-C 代码。
2. `clang` 通常在编译速度上比 `gcc` 更快，尤其是在增量编译时。
3. `clang` 提供了更详细和用户友好的错误和警告信息，这对于调试代码非常有帮助。

使用符号链接的原因：

- 符号链接相当于是快捷方式。如果要更换版本，则使其指向新的版本的实际文件即可
- 可以简化链接
- 易于维护



## Write-up 2

我选择的测试用例是lookup_table（LUT查找表），它是一种用于替代计算复杂度高的操作的数组或表格，通过预先计算并存储结果来加速查找和计算过程。

它的最核心代码如下：

```C++
template <typename T>
void apply_lut1(const T* input, T *result, const int count, const T* LUT) {
    for (int j = 0; j < count; ++j) {
        result[j] = LUT[ input[j] ];
    }
}
```

下面举一个例子来说明这段代码。

**任务目标：给定一个数组，返回这个数组中每个元素的平方数的数组**

- 构造LUT

```C++
int LUT[10] = {0, 1, 4, 9, 16, 25, 36, 49, 64, 81};
```

在已知需要查找的数字在0-10的范围内的前提下，提前计算好这些数字的平方数。

- 给出实际需要查找的数据

```C++
int input[5] = {2, 3, 5, 7, 9};
```

在这里需要返回这5个数字的平方数。例如：第一个需要查找的是2的平方数，则找到`LUT[2]=4`，此时将一个数学运算转变为一个搜索。在运算过程极为复杂，远大于搜索复杂度的时候，使用LUT能够极大地加快计算速率。



在该测试样例中，主要测试的情况包括：

- 使用函数将LUT搜索方法封装起来，也即上述的`apply_lut1`方法
- 在迭代过程中不使用函数，而是直接在迭代过程中将函数展开，也即`test_lut2`方法
- 一次循环寻找4个元素，而不是一个一个找，也即`test_lut3`方法
- 使用指针来优化数组查找，也即`test_lut4`方法

其余的测试用例是上述测试的组合。



**选择该测试样例的目的**：感受不同编译器和优化等级对这一算法的作用差异。



## Write-up 3

对`lookup_table.cpp`做的修改：这里涉及多个针对不同数据类型重复的测试，在分析过程中较为复杂，仅保留对`uint8`数据类型的分析。

对于`MakeFile`的分析：

- 宏定义

```makefile
#
# Macros
#

INCLUDE = -I.
```

`INCLUDE`宏指定了包含目录，`-I.` 表示当前目录。

- 编译标志
  - `CFLAGS`：用于 C 编译器的标志，包含包含目录和优化级别 `-O3`。
  - `CPPFLAGS`：用于 C++ 编译器的标志，包含 C++14 标准、包含目录和优化级别 `-O3`。
  - `CLIBS`和`CPPLIBS`：链接数学库 `-lm`。
  - `DEPENDENCYFLAG`：生成依赖项的标志`-M`。

```makefile
CFLAGS = $(INCLUDE) -O3
CPPFLAGS = -std=c++14 $(INCLUDE) -O3

CLIBS = -lm
CPPLIBS = -lm

DEPENDENCYFLAG = -M
```

- 目标程序

```makefile
#
# our target programs
#

BINARIES = lookup_table 
```

- 构建规则

```makefile
#
# Build rules
#

all : $(BINARIES)
```

`all`目标表示默认构建所有目标程序。

- 文件后缀

```makefile
SUFFIXES:
.SUFFIXES: .c .cpp
```

- 伪目标：

```makefile
# declare some targets to be fakes without real dependencies

.PHONY : clean dependencies
```

伪目标是没有实际依赖的目标。

- 清理构建文件：

```makefile
# remove all the stuff we build

clean : 
        rm -f *.o $(BINARIES)
```

删除所有生成的文件和目标程序

- 生成依赖项列表

```makefile
# generate dependency listing from all the source files
# used for double checking problems with headers
# this does NOT go in the makefile

SOURCES = $(wildcard *.c)  $(wildcard *.cpp)
dependencies :   $(SOURCES)
    $(CXX) $(DEPENDENCYFLAG) $(CPPFLAGS) $^
```

用于生成所有源文件的依赖项列表，帮助检查头文件问题。

- 特殊编译规则

```makefile
#
# special case compiles
#

exceptions : exceptions.c
    $(CC) $(CFLAGS) -o $@ exceptions.c $(CLIBS)

exceptions_cpp : exceptions.c
    $(CXX) $(CPPFLAGS) -D TEST_WITH_EXCEPTIONS=1 -o $@ exceptions.c $(CPPLIBS)
```

用于编译 `exceptions.c` 文件。

- 生成报告

```makefile
#
# Run the benchmarks and generate a report
#
REPORT_FILE = report.txt

report:  $(BINARIES)
    echo "##STARTING Version 1.0" > $(REPORT_FILE)
    date >> $(REPORT_FILE)
    echo "##CFlags: $(CFLAGS)" >> $(REPORT_FILE)
    echo "##CPPFlags: $(CPPFLAGS)" >> $(REPORT_FILE)
    ./lookup_table >> $(REPORT_FILE)
    date >> $(REPORT_FILE)
    echo "##END Version 1.0" >> $(REPORT_FILE)
```

`report`目标首先确保目标程序已经生成，然后运行基准测试并将结果写入报告文件中，包括开始和结束时间、编译标志等信息。

这里为了只进行lookup_table的测试，将其它内容全部删除。

为了记录代码的大小，在`report`中添加了如下两行代码

```makefile
echo "##Executable Size:" >> $(REPORT_FILE)
size ./lookup_table >> $(REPORT_FILE)
```



## Write-up 4

自动化脚本如下：

```sh
#!/bin/bash

# 定义了编译器和优化等级的组合
compilers=("gcc g++" "clang clang++")
opt_levels=("O0" "O1" "O2")

# 进入指定文件夹
cd CppPerformanceBenchmarks-master || exit

# 遍历编译器和优化等级的组合
for compiler in "${compilers[@]}"; do
  for opt_level in "${opt_levels[@]}"; do
    # 将gcc g++分别赋值给CC和CXX
    read -r CC CXX <<< "$compiler"
    
    # 清除之前的make后的文件
    make clean
    
    make report CC="$CC" CXX="$CXX" OPTLEVEL="-$opt_level"
    
    # 重命名report便于区分
    mv report.txt "report.txt.${CC}-${CXX}-${opt_level}"
  done
done
```



## Write-up 5

### 时间

- O1和O2在时间上普遍优于O0

  O0模式主要用于调试，它不会对代码有任何的理解和调整；O1和O2则会在保证代码正确性的基础上进行优化，会在一定程度上减少时间消耗。

- O1在时间上由于O2

  在 `-O2`优化下可能会引入额外的开销。例如，`-O2` 可能会进行更激进的内联和循环展开，这在某些情况下可能会导致代码膨胀和缓存命中率降低，从而影响性能；此外，在 `-O2` 优化下，编译器可能会进行更多的寄存器分配和指令调度，这在某些情况下可能会导致性能下降。

### 代码大小

结果如下表所示。

|               | text（代码段） | data（初始化数据） | bss（未初始化数据） | dec（总和） |
| ------------- | -------------- | ------------------ | ------------------- | ----------- |
| gcc g++       | 19524          | 728                | 48000096            | 48020366    |
| clang clang++ | 18204          | 728                | 48000064            | 48018996    |

不同编译器下得到的大小接近。