# Generator

很多人对生成器很感兴趣，于是这次打算谈谈这个。提到生成器，就不得不先谈谈迭代器（Iterator），这两个是紧密相连的。

我觉得了解一个东西，先从动机出发比较容易理解。迭代器感念的核心在于维护一个内部的私有迭代状态。

如果觉得抽象这里举个最简单的例子，以 for 循环一个数组为例，内部私有迭代状态就是循环时的 index 值，即现在循环到
哪儿了。于是本来我们写 for 循环需要维护一个 index 的自增，用迭代器之后就能省去这个繁琐过程了。代码前后对比就像
下面这样：

```javascript

var arr = [1, 2, 3];

// 用于生成迭代器的函数，它会返回一个迭代器实例。
var gen_iter = function (val) {
	var i = 0;
	var iter = function() {
		return val[i++];
	}
	return iter;
}

// 没使用
for (var i = 0; i < 10; i++) {
	item = arr[i];
	console.log(item);
}

// 使用后
var iter = gen_iter(arr);
while (item = iter()) {
	console.log(item);
}
```

注意这里例子没有用任何特殊的 js 新语法。动机很明了，我们少维护了一个很重要的变量 `i`。
而且大部分时候我们也不想关心迭代器这个黑盒子里到底在干什么，我们需要的只是有个东西能在我们调用它时，返回下一个
待处理对象。

讲完迭代器就是正题了，人们写多了迭代器之后发现，写迭代器其实是个很蛋疼的过程。很多时候你不得不维护复杂的
私有状态。

想看复杂的迭代器？你可以看看我最近写的这个函数：https://github.com/ysmood/nobone/blob/master/lib/kit.coffee#L306
这个函数实际上是用了迭代器的设计模式来解决问题的，但你很难看出哪里用了迭代器。

**接下来我们举个简单的例子，来说明为什么写迭代器很繁琐（正是因为繁琐才产生发明更简单工具的动机）。**

```javascript

// 不断循环输出 星期一 到 星期三 以及对应的 数值。
// 这例子里不单用了复杂的 swith 判断 index 的区间，在最后 default 还有类递归用法。
// 实际项目需求往往只会更复杂，你需要像这样维护无聊的，重复的代码片段。
var gen_iter = function () {
	var i = -1;
	var iter = function () {
		i++;
		switch (i) {
			case 0:
				return '月曜日';
				break;
			case 1:
				return '火曜日';
				break;
			case 2:
				return '水曜日';
				break;
			default:
				if (i < 6)
					return i - 2;
				else
					i = -1;
					return iter();
		}
	}
	return iter;
}

var iter = gen_iter();

for (var i = 0; i < 10; i++)
	console.log(iter());

```

**同样的逻辑用新语法的 generator 来做就异常简单了**

_(为了节省大家时间这里没有提及 Iterator() 这个函数，你可以自己去查阅)_

```javascript

// 要运行这段代码，请访问地址 chrome://flags，然后开启 harmony，重启 chrome
var gen_iter = function* () {
	while (true) {
		yield '月曜日';
		yield '火曜日';
		yield '水曜日';
		for (var i = 1; i < 4; i++)
			yield i;
	}
}

var iter = gen_iter();

for (var i = 0; i < 10; i++)
	console.log(iter.next().value);

```

实际上 yield 的底层实现就是类似我上面的 switch 的原理，在内部建立多个 yield 断点，每次运行调用迭代器的时候，
改变它内部维护的 index，每次只运行两个 yield 之间的代码。

### 然后你就问了，这跟并发编和尾调地狱有半毛钱关系？

欲知后事，且听 ys 某下回分解。

下回预告：从 concurrent 和 parallel 的区别来理解 Generator 价值。
