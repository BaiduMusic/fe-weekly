<style type="text/css">

.blue {
	color: #004080;
}

.orange {
	color: #ff8000;
}

</style>

## 从 Concurrent 和 Parallel 的区别来理解 Generator 价值

很多人都觉得 并发（concurrent） 和 并行（parallel） 是同一个概念，但事实上根据上下文的不同这两个可以是不同概念。
比如我们提到 编程方法 和 设计模式 时这两个就是不同的概念。

这里有个 stackoverflow 的提问: [Difference between concurrent programming and parallel programming](http://stackoverflow.com/questions/1897993/difference-between-concurrent-programming-and-parallel-programming)

里面画了张图来解释区别：

并发
```
             --  --  --
          /              \
     >---- --  --  --  -- ---->>
time >------------------------>>
```

并行或并发
```
          ------
         /      \
     >-------------->>
time >-------------->>
```

并行编程要求一定是在多个线程（thread）执行。且多线程是程序相对系统的，也可以是单核多线程。

并行 通常是系统给出接口让程序能控制如何使用系统的线程资源。而 <b class='orange'>这里提到的 并发 通常是给出接口让程序能控制代码的执行方式</b>。

得到这个结论之后我们就能发现 Generator 和 并发之间的关系了。Generator 的 `yield`、`next` 等接口能让我们通过语法来控制代码本身的执行方式。

也就是增加了代码编写的灵活度，很多人认为 并发编程 能提升代码的运行效率，这是片面的理解。解决同样的目的，使不使用 Generator，理论上代码性能都不会有
什么改变。<b class="orange">它真提升的是解决问题的可能性</b>。

比如经典的 “生产者-消费者问题”。我看过的最好的示例就是 Lua 作者写的：[Pipes and Filters](http://www.lua.org/pil/9.2.html)。
大二时看的，如今仍受益匪浅。他将 “生产者-消费者问题” 转化为了 “是谁在主导主循环” 问题。
显然在生产消费问题里，没有主导者，就像“鸡生蛋，蛋生鸡问题”一样，正是因为如此，大家才觉得这问题很棘手。

当然不是每个 FE 都熟悉 Lua，而且生产消费问题也很少人会在 FE 编程里碰到，这里我们只演示如何利用 Generator
解决 callback hell 代码风格的问题。

<script type="text/javascript">
	var async_task = function (index, callback) {
		setTimeout(function () {
			var data = 'data: ' + index;
			callback(data);
		}, Math.random() * 100);
	};

	// 串行执行异步任务。
	async_task(0, function (data) {
		console.log(data);

		async_task(1, function (data) {
			console.log(data);

			async_task(2, function (data) {
				console.log(data);
			});
		});
	});
</script>

不使用 Generator 的一般实现：

```javascript
var async_task = function (index, callback) {
	setTimeout(function () {
		var data = 'data: ' + index;
		callback(data);
	}, Math.random() * 100);
};

// 串行执行异步任务。
async_task(0, function (data) {
	console.log(data);

	async_task(1, function (data) {
		console.log(data);

		async_task(2, function (data) {
			console.log(data);
		});
	});
});
```

使用 Generator 的理想效果：

```javascript
sync_scope(function* () {
	console.log(async_task(0));
	console.log(async_task(1));
	console.log(async_task(2));
});
```

使用 Generator 的实际代码示意：

<script>
	// 生成适应 yield 接口的异步函数
	var create_task = function (index) {
		return function async_task (callback) {
			setTimeout(function () {
				var data = 'data: ' + index;
				callback(data);
			}, Math.random() * 100);
		};
	};


	var sync_scope = function (generator) {
		var iter = generator();

		// 这是一个对应异步任务的 callback
		var callback = function (data) {
			var yield_item = iter.next(data);

			if (!yield_item.done) {
				var task = yield_item.value;

				// 触发下一个 yield
				task(callback);
			}
		};

		// 启动递归
		callback();
	};

	// 利用 yield 暂停代码
	sync_scope(function* () {
		console.log(yield create_task(0));
		console.log(yield create_task(1));
		console.log(yield create_task(2));
	})
</script>

```javascript
// 生成适应 yield 接口的异步函数
var create_task = function (index) {
	return function async_task (callback) {
		setTimeout(function () {
			var data = 'data: ' + index;
			callback(data);
		}, Math.random() * 100);
	};
};

var sync_scope = function (generator) {
	var iter = generator();

	// 这是一个对应异步任务的 callback
	var callback = function (data) {
		var yield_item = iter.next(data);

		if (!yield_item.done) {
			var task = yield_item.value;

			// 触发下一个 yield
			task(callback);
		}
	};

	// 启动递归
	callback();
};

// 利用 yield 暂停代码
sync_scope(function* () {
	console.log(yield create_task(0));
	console.log(yield create_task(1));
	console.log(yield create_task(2));
})
```

可以看到， Generator 并不是随便拿上来就能用，就跟使用 Promise 一样需要按照一定的模式实现函数。
换句话说，其实用起来还是有一定复杂度的，并不是完美的方案。

除此之外 `yield` 和 `return` 一样只能传入一个参数，如果你运行这样的代码 `yield(1,2,3)`，只有最后的 `3` 会被传到 `next`。

下面是用函数式编程的一种解决方式：

<script type="text/javascript">
	var task = [0, 1, 2];

	var run = function (data) {
		if (data)
			console.log(data);

		var index = task.shift();
		if (index != null)
			async_task(index, run);
	}

	run();
</script>

```javascript
var task = [0, 1, 2];

var run = function (data) {
	if (data)
		console.log(data);

	var index = task.shift();
	if (index != null)
		async_task(index, run);
}

run();
```

如果我们使用函数式编程处理这个问题，代码理解难度可能更低，但代码的统一度会比使用了 Generator 的差。
从异常捕获角度来讲，使用 Generator 显然会让代码结构更容易理解。

使用 Generator 也会有些蛋疼的问题，比如某段代码里忘记写或者多写了几个 yield，这时很可能让代码调试变得非常奇怪。

总体来说不论使用哪种方案，你都无法避免将 callback 封装一次。
使用 Generator 之后，虽然原理更加复杂，但明显会让主逻辑部分的代码书写更直观简洁。
