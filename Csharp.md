[文档](https://docs.microsoft.com/zh-cn/dotnet/csharp/getting-started/introduction-to-the-csharp-language-and-the-net-framework)

C# 是类型安全的面向对象的语言，运行在 .NET平台，运行时为clr（公共语言运行时）。扩展名`.cs`。

# 项目创建

创建一个新程序和生成脚本， 该程序和生成脚本分别位于文件 `Program.cs` 和 `hello.csproj` 中

```shell
dotnet new <type> -o projName
```

也可使用visual studio创建项目。运行程序可在项目目录中执行：

```shell
dotnet run
```

## 数据类型

强类型需声明变量类型。

- 数字

  - `int` 整数
  - `float` 单精度浮点数
  - `double` 双精度浮点数
  - `decimal`  比double的数值范围小但精度更高，数字后面必须加上`M`如`20M`

- 字符串 `String`

- 列表`List`  创建需要new并指定类型 `new List<基础数据类型> {元素1,元素2}`

  ```c#
  var list1=new List<string> {"a", "b"}
  ```

  