在阅读了一定的源代码之后，我得到了如下结论：

* seajs 的 CMD 模式在 requirejs 里已经实现了，且原理相同。都是使用了极其不安定的 Function.prototype.toString()，通过正则匹配分析对依赖进行预加载。
  换句话说 seajs 的优势 requirejs 现在已经几乎全部有了，比如 requirejs 也支持丰富的插件。

* 在 API 方面，requirejs 更加统一，利用了函数重载的方式实现 AMD 和 CMD，而 seajs 则用了 `require` 和 `require.async` 两个函数来实现 CMD 和 AMD。
  关于这点，可以读读 requirejs 的源代码，重载写的很经典，用到了 Function.length，大大提升了性能。

* 对初学者来说 seajs 更容易损失加载性能，类似 AMD 的条件加载在 CMD 会失效，且这情况只会发生在浏览端，node 不会。

* 从社区活跃度和文档的完备度来看，requirejs 比较完备。

* requirejs 体积很大，min 之后有 15K，seajs 只有 6K。