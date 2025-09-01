---
title: 为 C++程序写 rustbinding
categories:
  - rust
tags:
  - c++
  - bingen
abbrlink: 12714
date: 2024-08-12 23:24:49
---

# 为 C++程序写 rustbinding

## AutoCxx 与 CWrapper+Bindgen

[为 c++程序写 ruts-binding](https://www.notion.so/c-ruts-binding-d617fe66712241ca830107a1c2020761?pvs=21)

在代码的世界中，还是 c和 cpp站绝大多数，现在提一个比较常见的需求：提供一个 c++的程序，最终需要再 rust中调用 c++程序提供的接口。

一般来说有两个方法

1. 直接使用 cxx autocxx为 rust代码生成一份 unsafe的代码，然后直接调用
2. 第二种方法比较路径稍长，先针对 c++代码的 header 写一份 c风格的头文件cwrapper，然后针对 c的头文件写一份 c头文件的实现。接下来编译自己的cwrapper，生成一份新的动态库。接下来使用 bindgen 根据 cwrapper生成一份 unsafe rust。最后在 rust代码中调用。

总体来说 cxx 或者 autocxx 可能性能会更好一些，但是 autocxx并不能搞定一切。第二种方法胜在稳定，毕竟 c的 abi比较稳定。本文将采用后一种方法。

## 速成材料

技术基础是：会 rust，不会 c++或者 c。所以需要速成，了解 c和 c++。如果彻底不会 c++，写 bingen 无从谈起。

下面是一些材料

1. https://www.youtube.com/watch?v=KJgsSFOSQv0&t=76s
2. https://www.youtube.com/watch?v=ZzaPdXTrSb8
3. https://www.runoob.com/cplusplus/cpp-variable-scope.html

第一个为 feeCodeCamp的 c课程，三小时速成。

因为 c++比较难，可以学习第二个教程一小时速成，接下来看菜鸟教程的文档。注意不要纠结细节，否则无法速成。学成 C++已经数年以后 🥳，毕竟最终目的并非写 c++。

或者也可以看 freecodecamp的 c++教程，大概四小时看完。

## CPP部分

### 库文件准备

https://github.com/TigerInYourDream/cppExample

c++部分代码已经上传 github。常见的c++项目大概使用 cmake编译，因为速成材料中没有讲 cmake，所以直接用 g++或者 clang编译。

```cpp
#include <ctime>
#include <iostream>
using namespace std;
namespace MyNamespace {
    class MyClass {
    public:
        MyClass();
        ~MyClass();
        void myMethod();
    };
}
MyNamespace::MyClass::MyClass() {
    cout << "Constructor called" << endl;
}
MyNamespace::MyClass::~MyClass() {
    cout << "Destructor called" << endl;
}
void MyNamespace::MyClass::myMethod() {
    cout << "myMethod called" << endl;
}
// int main() {
//     MyNamespace::MyClass obj;
//     obj.myMethod();
//     return 0;
// }


```

```c++
//下面的是头文件

#ifndef MYCLASS_HPP
#define MYCLASS_HPP
namespace MyNamespace {
    class MyClass {
    public:
        MyClass();
        ~MyClass();
        void myMethod();
    };
}
#endif // MYCLASS_HPP
```

c++源文件和头文件在此。一个非常简单的代码，为了在后续使用 c风格的 wrapper。特意使用了 namespace class这些 c没有的特性。大致解释下代码 分别有构造函数，析构函数（类似与 rust的 Drop）和一个成员函数（或者这个称为方法）。

> clang++ -c -fPIC MyClass.cpp -o MyClass.o
>
> clang++ -dynamiclib -o libMyClass.dylib MyClass.o
>
> ​	-dynamiclib 选项表示生成动态库。
>
> ​	-o libMyClass.dylib 指定输出文件的名称为 libMyClass.dylib。
>
> 

c++的二进制产物生成分两步 

1. 编译
2. 链接

编译生成 .o的编译产物，然后链接生成动态库。因为我的编程环境为 mac，所以我使用 clang++ 且选择生成 dylib。如果是 linux考虑使用 g++和生成 so(这一类更常见)

### C包装

首先根据暴露的库文件包装一个 c风格的头

```cpp
#ifndef MYCLASSWRAPPER_H
#define MYCLASSWRAPPER_H
#ifdef __cplusplus
extern "C" {
#endif
typedef struct MyClassOpaque MyClassOpaque;
/* typedef (struct MyClassOpaque) MyClassOpaque; */
typedef MyClassOpaque* MyClassHandle;
MyClassHandle MyClass_create();
void MyClass_destroy(MyClassHandle handle);
void MyClass_myMethod(MyClassHandle handle);
#ifdef __cplusplus
}
#endif
#endif // MYCLASSWRAPPER_Htypedef struct MyClassOpaque MyClassOpaque;
```

c的头文件如上所示，关键是使用不透明指针



> 不透明指针(Opaque Pointer)是一种特殊类型的指针,它隐藏了所指向的具体数据类型的详细信息。不透明指针只提供了指针的操作,而不暴露指针所指向的数据的类型和结构。
>
>  
>
>  typedef struct MyClassOpaque MyClassOpaque; 是一种特别的写法 实质相当于 对 struct MyClassQpaque 的别名，以后用MyClassOpaque 不用带 Struct关键字。
>
>  
>
>  typedef MyClassOpaque* MyClassHandle;
>
> 直接定义不透明指针



有了这个C风格的头还不够，还需要一份实现代码

```cpp
#include "MyClassWrapper.h"
#include "myclass.hpp"
using namespace MyNamespace;
extern "C" {
    struct MyClassOpaque {
        MyClass* instance;
    };
    MyClassHandle MyClass_create() {
        MyClassOpaque* opaque = new MyClassOpaque;
        opaque->instance = new MyClass();
        return opaque;
    }
    void MyClass_destroy(MyClassHandle handle) {
        MyClassOpaque* opaque = static_cast<MyClassOpaque*>(handle);
        delete opaque->instance;
        delete opaque;
    }
    void MyClass_myMethod(MyClassHandle handle) {
        MyClassOpaque* opaque = static_cast<MyClassOpaque*>(handle);
        opaque->instance->myMethod();
    }
}
```

实际实现的代码如上。使用 exrern “C” 包装 相当于 rust的 extern “C” 和 nomangle。注意对应实现析构函数的 destroy函数，注意 delete内存。

接下来

```cpp
clang++ -c -fPIC MyClassWrapper.cpp -o MyClassWrapper.o
clang++ -dynamiclib -o libMyClassWrapper.dylib MyClassWrapper.o -L . -lMyClass
-dynamiclib 选项表示生成动态库。
-o libMyCombined.dylib 指定输出文件的名称为 libMyCombined.dylib。
-L. 选项告诉链接器在当前目录中查找库文件。
-lMyClass 选项告诉链接器链接到 libMyClass.dylib 库文件。
```

就是编译 接下来链接第一次生成c++的动态库 MyClass。 注意生成的动态库有 lib前缀。他们的依赖关系如下MyClassWrapper 链接 MyClass. 这个库的链接非常重要。

现在就有了一份 c风格的头文件和两个动态库 MyClass MyClassWrapper

本人对 c++并不熟悉如果有其他注意的点好改进，欢迎提出改进

## Rust部分

https://github.com/TigerInYourDream/bindexample

rust部分直接选择使用 bindgen.生成 rust代码

```cpp
├── Cargo.lock
├── Cargo.toml
├── build.rs
├── include
│   └── MyClassWrapper.h
├── lib
│   ├── libMyClass.dylib
│   └── libMyClassWrapper.dylib
├── src
│   ├── bindings.rs
│   └── main.rs
├── target
```

rust项目的结构如上所示。include中为 c风格的头文件。主要注意的点存在于 build.rs中

```cpp
extern crate bindgen;
use std::path::PathBuf;
use bindgen::CargoCallbacks;
fn main() {
    println!("cargo:rustc-link-search=native=./lib");
    println!("cargo:rustc-link-lib=dylib=MyClassWrapper");
    println!("cargo:rustc-link-lib=dylib=MyClass");
    // 生成 Rust 绑定
    let bindings = bindgen::Builder::default()
        .header("wrapper.h")
        .parse_callbacks(Box::new(CargoCallbacks::new()))
        .generate()
        .expect("Unable to generate bindings");
    // 将生成的绑定写入 src/bindings.rs 文件
    let out_path = PathBuf::from("./src/");   
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}
```

技巧 

1. 生成代码可以直接生成到 src目录下，否则会直接生成到 build目录下，也就是环境变量 OUT_DIR输出的环境的。可以生成到src 手动引用。这样生成的代码可以像正常代码一样可以被正常引用，也可以直接使用 rust analysis 分析。 如果使用 cspell记得单独排除这个文件。
2. 可以在根目录下外加一个 wrapper.h文件，在 wrapper中指定外部的头文件。或者也可以参考 bingen的最佳实践。目前个人最佳实践是这样。
3. 三个打印分别是 link-search 目录，下面两个是具体搜索的库，不要带前缀和后缀。

### 运行的注意点

1. 注意 build.rs只会管 build时刻的链接目录，运行的时候并不会管。如果编译的时候提示找不到动态库，可以修改 search目录，或者仔细观察目录，把库的目录直接移动到项目根目录下（因为根目录也是默认的库搜索路径），还有很多其他路径，可以可以删除观察。
2. cargo r氛围两阶段，一个是 build阶段，build阶段 build.rs中的设置是有用的。第二个阶段为运行，相当于执行 ./xxxx。  所以直接 cargo r -r 会找不到库路径

```cpp
export DYLD_LIBRARY_PATH=/path/to/dylib:$DYLD_LIBRARY_PATH
直接使用上面的环境变量设置动态库的文件目录  
注意上面的适用于 MAC的 dylib
linux 则是设定LD_LIBRARY_PATH
```

可以使用 just来设置环境变量 和 一组编译运行计划来简化命令行。因为 just和和编写 bindgen 无关，随意不在本文提起。

然后就可以执行了

![](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/img/821723477517_.pic.jpg)
