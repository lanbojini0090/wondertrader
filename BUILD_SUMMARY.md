# WonderTrader 编译全流程总结

本文档总结了 WonderTrader 项目在 macOS 环境下的编译全流程、模块依赖关系以及最终产物结构。

## 1. 编译环境要求

*   **操作系统**: macOS (支持 Linux/Windows，本文档侧重 macOS)
*   **构建工具**: CMake (建议 3.10+)
*   **编译器**: 支持 C++17 的编译器 (Clang/GCC)
*   **核心依赖**:
    *   **Boost**: 主要使用 `filesystem`, `thread`, `asio`, `date_time` 等库。
    *   **libiconv**: 用于字符编码转换 (macOS 下需要显式链接)。
    *   **fmt**: 格式化库 (部分模块使用)。
    *   **spdlog**: 日志库 (部分模块使用)。

## 2. 构建流程

WonderTrader 使用标准的 CMake 构建流程。

### 步骤

1.  **创建构建目录**:
    ```bash
    mkdir build
    cd build
    ```

2.  **配置项目**:
    ```bash
    cmake ..
    ```
    *注意*: macOS 上可能需要配置 `CMAKE_PREFIX_PATH` 以找到 brew 安装的库 (如 boost)。

3.  **执行编译**:
    ```bash
    make -j$(nproc)
    ```
    或者使用 IDE (如 VS Code) 的构建功能。

4.  **安装/生成产物**:
    编译完成后，可执行文件和库文件会生成在 `build/bin` 目录下（或者是 `install` 目录，取决于配置）。

## 3. 模块依赖与结构

项目采用模块化设计，主要分为 **核心库**、**可执行程序** 和 **插件模块**。

### 3.1 核心基础模块 (Static Libraries)

这些模块是系统的基石，通常编译为静态库 (`.a`)，被其他模块链接。

| 模块名称 | 源码位置 | 功能描述 | 依赖 |
| :--- | :--- | :--- | :--- |
| **WTSUtils** | `src/WTSUtils` | 基础工具库 (字符串处理, 时间, 文件等) | 内嵌 `yamlcpp`, `zstdlib`, `lmdb` |
| **Share** | `src/Share` | 共享代码库 (公共数据结构, 接口定义) | `WTSUtils` |
| **WtCore** | `src/WtCore` | 交易引擎核心逻辑 (策略调度, 数据管理) | `WTSUtils`, `Share` |
| **WtDtCore** | `src/WtDtCore` | 数据组件核心逻辑 | `WTSUtils`, `Share` |

### 3.2 插件模块 (Shared Libraries / DynLibs)

这些模块实现具体的接口 (如行情解析、交易通道)，编译为动态库 (`.dylib` / `.so`)，由主程序动态加载。

| 类别 | 典型模块 | 源码位置 | 产物目录 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| **Parsers** (行情) | `ParserCTP`, `ParserXTP` | `src/Parser*` | `bin/parsers/` | 负责对接不同柜台的行情接口 |
| **Traders** (交易) | `TraderCTP`, `TraderXTP` | `src/Trader*` | `bin/traders/` | 负责对接不同柜台的交易接口 |
| **Executers** (执行) | `WtExeFact` | `src/WtExeFact` | `bin/executers/` | 执行算法工厂 |

### 3.3 可执行程序 (Executables)

系统的入口程序。

| 程序名称 | 源码位置 | 功能描述 | 依赖 |
| :--- | :--- | :--- | :--- |
| **WtRunner** | `src/WtRunner` | **主交易程序**，加载策略和插件运行 | `WtCore`, `WTSUtils`, `Share`, `Boost` |
| **WtBtRunner** | `src/WtBtRunner` | 回测运行程序 | `WtBtCore`, `WTSUtils`, ... |
| **WtDtServo** | `src/WtDtServo` | 数据服务程序 | `WtDtCore`, `WTSUtils`, ... |

## 4. 最终产物结构

编译成功后，`install` 目录或 `bin` 目录结构通常如下：

```text
bin/
├── WtRunner          # 主程序
├── WtBtRunner        # 回测程序
├── WtDtServo         # 数据服务
├── lib/              # 核心库 (如果配置为动态库)
├── parsers/          # 行情解析插件
│   ├── libParserCTP.dylib
│   ├── libParserXTP.dylib
│   └── ...
├── traders/          # 交易通道插件
│   ├── libTraderCTP.dylib
│   ├── libTraderXTP.dylib
│   └── ...
└── executers/        # 执行算法插件
    └── libWtExeFact.dylib
```

## 5. 常见问题与注意事项 (macOS)

1.  **iconv 链接问题**: macOS 的 `libiconv` 是系统自带的，但在 CMake 中可能需要显式链接。
    *   *解决方法*: 在 `CMakeLists.txt` 中添加 `find_package(Iconv REQUIRED)` 并链接 `Iconv::Iconv`，或者手动链接 `/usr/lib/libiconv.dylib`。
2.  **Boost 路径**: 如果使用 Homebrew 安装的 Boost，CMake 可能找不到。
    *   *解决方法*: `cmake -DBOOST_ROOT=/opt/homebrew/opt/boost ..`
3.  **C++ 标准**: 项目要求 C++17。
    *   *检查*: 确保 `CMakeLists.txt` 中有 `set(CMAKE_CXX_STANDARD 17)`。
