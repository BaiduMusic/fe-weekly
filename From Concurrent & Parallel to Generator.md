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
它是一种

### <b class='blue'>系统执行程序的方式</b>

相比而言并发编程就不受线程的限制，它可以是在单线程里。它是一种

### <b class='blue'>程序执行代码的方式</b>

换句话说，并行 通常是系统给出接口让程序能控制如何使用系统线程资源。而 <b class='orange'>这里提到的 并发 通常是给出接口让程序员控制代码的执行顺序</b>。

得到这个结论之后我们就能发现 Generator 和 并发之间的关系了。Generator 的 `yield`、`next` 等接口能让我们通过语法来控制代码本身的执行顺序。

也就是增加了代码编写的灵活度，很多人会有误解，认为 并发编程 能提升代码的运行效率，这是片面的理解。解决同样的目的，使不使用 Generator，理论上代码性能都不会有
什么改变。<b class="orange">它真正增加的是解决问题的可能性</b>。

比如经典的 “生产者-消费者问题”。我看过的最好的示例就是当年 Lua 作者写的：[Pipes and Filters](http://www.lua.org/pil/9.2.html)。
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

不使用 Generator 的一般实现：

```javascript
var async_task = function (index, callback) {
	setTimeout(function () {
		var data = 'data: ' + index;
		callback(data, 'asdf');
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
