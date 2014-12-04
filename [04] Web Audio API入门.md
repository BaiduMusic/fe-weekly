HTML5引入了Audio标签来处理流式音频，这极大方便了Web开发者 —— 借助Audio标签和简单的API，能轻松实现基础的音频播放。我们的[MuPlayer][1]就基于Audio，提供了一个跨平台、轻量级的音频播放解决方案。但对于游戏音效和复杂音频应用而言，往往需要用到混音、滤波、声道延迟等更底层的音效处理手段以弥补Audio的局限，因此，[Web Audio API][2]便应运而生。

文章将结合代码和示例对Web Audio API做一个概要介绍，以便让大家对Web端音频处理的种种可能和实际应用有一个直观印象。在深入之前，有必要先了解一下Audio API提供的几个主要接口和特性：

API名称 | 描述
--------|-----
AudioContext|AudioContext包括一组AudioNode对象和它们之间的连接。它允许信号以任意方式的路由到达AudioDestinationNode（最终用户耳朵听到的内容）。各音频操作节点在AudioContent环境中被创建，而后串联起来。多数情况下，每个文档只有一个AudioContext。
AudioNode|AudioNode是搭建AudioContext的基础组成。一个AudioNode定义了音频源、音频目的以及中间处理模块。这些模块可以相互连接以构成渲染音频到音频硬件的处理流程图。每个节点可以有输入和输出。而源节点没有输入、只有一个输出。
AudioBuffer|接口定义了贮存内存的音频资源（特别是单声音频和其他音频剪辑）。接口格式是非交叉的IEEE 32位范围在-1到1之前的线性脉冲编码调制（PCM，Pulse-code modulation），并可拥有一或多个声道。
AudioParam|AudioParam用于控制AudioNode某个方面功能，如音量。可以通过设置属性（如波封、声音渐减、低频振荡器、滤波器扫描）来即时修改。或者在某个具体时间（可依赖AudioContext.currentTime来精确指定）控制值的改变。通过这种方式，可以将基于时间轴的任意自动化曲线赋给AudioParam。除此之外，AudioNode 输出的音频信号可以作为AudioParam的输入，和内部参数值汇总。
GainNode|改变音频信号的增益是音频应用的一项基本操作。GainNode 是构建混音器的基础组成部分。GainNode是个单输入、单输出的 AudioNode，它将输入音频信号乘以增益属性(可能是时变的)，然后将结果复制到输出。

由此可见，Web Audio API定义了一系列在Web应用中用于处理、合成音频的高层Javascript接口。其核心思想是构建了一个音频处理路由图，在这个路由图中，各种负责具体功能的AudioNode对象被串联在一起，整体来决定音频的渲染和效果。实际的处理过程将主要在底层实现（通常是对 C 、C++的编译优化），但对外暴露相应的Javascript API以供方便的处理、合成音频。

### 音频路由图
![音乐路由图][3]

上面特别提到了音频路由图的概念，简单说，如上图所示，音频路由指从音频源到最终输出设备间音频数据所经历的处理流程。Web Audio Api规范了音频处理节点的连接方式，在音频源与输入设备见，可以通过统一的规范很方便的接入音频处理节点，获得并处理音频数据。
这里有一个在线的音频路由Demo，有助于理解上述处理流程：[https://github.com/cwilso/WebAudio][4]

### 从AudioContent开始
上面我们提到，AudioContent是负责管理、播放声音的对象，一个页面（Document）中只能存在一个AudioContent。但这并没有任何限制，你可以在一个content里轻松创建多个复杂而独立的音频路由。

可以将content对象理解为为了简化整个处理流程而对外暴露API接口的持有者。换句话说，好多很有意思的Web Audio API功能，如创建AudioNodes 或解码音频文件等，都是context对象的方法。下面，咱们来看一下如何初始化AudioContent（早期版本的Chrome浏览器须加上webkit前缀，如果想屏蔽这些兼容性差异，可考虑引入[AudioContext-MonkeyPatch][5]）：
```javascript
var context;
if (typeof AudioContext !== 'undefined') {
    context = new AudioContext();
} else if (typeof webkitAudioContext !== 'undefined') {
    context = new webkitAudioContext();
} else {
    throw new Error('浏览器暂不支持Web Audio API :(');
}

```

### 创建音频源
与使用Audio标签不同的是，你无法设置一个音频地址并直接加载，通常，需要通过[XMLHttpRequest][6]在异步请求中加载音频内容，然后通过AudioContext实例的decodeAudioDate方法获取到具体的音频buffer数据，共后续音频源节点使用。具体实现如下：
```javascript
function loadAudioFile(url, callback) {
    var request = new XMLHttpRequest();

    request.open('GET', url, true);
    request.responseType = 'arraybuffer';

    // 绑定异步请求的回调
    request.onload = function() {
        context.decodeAudioData(request.response, function(buffer) {
            callback(buffer);
        });
    };

    request.send();
}
```
有了音频buffer，我们便可创建一个音频源节点，并将buffer数据添加到音乐源上。
```javascript
// 创建音频源节点
var source = context.createBufferSource();
// 将音乐源节点绑定具体的音频buffer
source.buffer = buffer;
```

### 将音频源连接到输出设备
![enter image description here][7]

还记得我们文章开头提到过的音频路由吗？如果把音频源节点直接连接到输出设备（通常情况下是耳机或扬声器），就构成了如上图所示的最简音频路由。实现的代码非常简单：
```javascript
// 将音频源与硬件连接
soundSource.connect(context.destination);
// 开始从头播放
soundSource.start(0);
```
至此，我们便可通过音频输出设备听到加载的音频了。完整的源码可以来这里查看：http://jsbin.com/bazuyaji/1/watch?js

### 音量控制
在音频正确播放的基础上，我们可以在从音频源节点到输出设备间的音频路由上连入各种中间处理模块（AudioNode），以达到我们对音频源的处理、控制。最简单而实用的例子莫过于调节音量，下面我们看看如何实现对音量的控制。
```javascript
// 控制音量的节点
var volume = context.createGain();
 
// 设置音量，音量范围是[0, 1]
volume.gain.value = 0.8;

// source节点先连接到对音量控制的volume增益节点上
// volume增益节点再连接到最终的输出设备上
source.connect(volume);
volume.connect(context.destination);
```
可见，音频源到输出设备见的各路由的节点负责对音频的处理、控制。如下图示意，各节点通过统一的`connect`接口连接到一起。
![enter image description here][8]

### 音效增强
对于专业的播放软件，一般都拥有音效均衡器，让听众可以根据不同的场景控制音频中各声段的大小，来达到适合该场景的试听效果，这是一种常见的音效增强需求。
![enter image description here][9]

均衡器的实现原理是，音频通过滤波装置（BiquadFilter）会被分离出特定的音频频段，通过控制调节各音频频段的音量来达到调整整体音效的效果。比如，我们知道，150Hz-500Hz的频段是声音的结构部分，人声的可听区域位于这个频段，如果我们对该频段做一定的增强，将有助于凸显音频中的人声。
```javascript
var filter = context.createBiquadFilter();

// PEAKING代表波峰滤波器允许所有的频率通过
// 对一个范围内的频率加上一个激励或者衰减
filter.type = filter.PEAKING || 'peaking';

// Q控制被处理的频率范围的宽度，值越大应用的范围越窄
filter.Q = 1.4;

// frequency表示会应用这个激励(或者衰减)的频率下限
filter.frequency = 500;

// 激励，单位为 db。如果值为负表示频率将会衰减
filter.gain.value = 20;

// 将音频源、处理节点及硬件连接到一起
source.connect(filter);
filter.connect(volume);
volume.connect(context.destination);
```

### 更多探索
Web Audio API为前端开发者打开了一扇在浏览端处理、分析音频的大门，本篇文章仅仅是一个入门级的介绍。借助Audio API提供的便捷接口，我们能找到很多音频相关的实际应用。比如，我们[百度音乐前端团队][10]就曾做过一些音频应用的尝试：http://labs.music.baidu.com/demo/audiolab/ 。

最后，为了更好的了解并探索“门后”的精彩世界，不妨抽出时间，读读我们翻译的[官方地图（Web Audio API官方文档中文版）][11]，以便按图索骥：）
当然，目前的翻译难免有疏忽之处，也欢迎大家来共同完善之：https://github.com/Baidu-Music-FE/WebAudioAPI 。

  [1]: http://labs.music.baidu.com/muplayer/doc/
  [2]: http://webaudio.github.io/web-audio-api/
  [3]: http://music.baidu.com/cms/topics/web_audio_api/audio-route.jpg
  [4]: https://github.com/cwilso/WebAudio
  [5]: https://github.com/cwilso/AudioContext-MonkeyPatch
  [6]: http://www.html5rocks.com/en/tutorials/file/xhr2/
  [7]: http://music.baidu.com/cms/topics/web_audio_api/connect.jpg
  [8]: http://music.baidu.com/cms/topics/web_audio_api/volume.jpg
  [9]: http://music.baidu.com/cms/topics/web_audio_api/filter.jpg
  [10]: http://labs.music.baidu.com/
  [11]: http://pan.baidu.com/s/1dDuxjvN
