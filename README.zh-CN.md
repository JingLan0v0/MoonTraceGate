# MoonTraceGate

用基线和候选版本的 Chrome Trace JSON 做性能预算检查。项目在 MoonBit 中把同线程的
嵌套耗时拆成总耗时与自身耗时，再用绝对上限和增长上限找出具体超标阶段。适合在构建、
渲染或数据处理流水线发布前，检查已埋点阶段是否退化。

根据 [toolchain.json](toolchain.json) 安装固定工具链，在项目根目录运行
`node examples/demo.mjs`。它会重新构建 CLI，自动验证正常放行、预算拦截、
坏 trace 诊断，并执行实际 Node 数据处理任务、采集并回放其四个事件区间。

| 演示 | 可复核结果 |
| --- | --- |
| candidate-pass.json | 自身耗时 2,000 ns，退出 0 |
| candidate-regression.json | 候选自身耗时 5,000 ns，比基线多 3,000 ns，同时超过两项预算，退出 1 |
| candidate-invalid.json | 定位未闭合的开始事件，标准输出为空，退出 2 |

直接检查固定样本：

    moon run cmd/main --target js -- examples/baseline.json examples/candidate-pass.json examples/budgets.json

可用 `node examples/capture.mjs capture.json` 录制真实样例。输入、规则、报表和
限制见 [格式说明](docs/format.md)。库入口为 `profile`、`Profile::lookup` 与
`check_budget`，完整示例位于 `examples/library`。自身耗时指区间扣除同线程直接
子区间后的墙钟时间。各线程的聚合可相加，含义是累计区间耗时。

**多次采样。** 0.2.0 支持同一工作负载每侧 3 至 32 次追踪，报告会保留每次测量。
固定样例在 p50 下放行，在 p95 下拦截尖峰。候选样本缺少关键事件会单独暴露。
直接运行 `node examples/demo.mjs` 即可核对上述结果和三次实际采集。
详见[多次采样规则](docs/format.md#multi-run-gate)。

已发布 [Mooncakes 0.2.1](https://mooncakes.io/docs/JingLan0v0/tracegate@0.2.1)。
在使用方项目执行 `moon add JingLan0v0/tracegate@0.2.1`，并在 `moon.pkg` 导入
`JingLan0v0/tracegate`。验收使用 `node scripts/verify.mjs`，Windows 包装检查使用
`./scripts/powershell-smoke.ps1`。实际结果见 [验收记录](docs/acceptance.md)。
