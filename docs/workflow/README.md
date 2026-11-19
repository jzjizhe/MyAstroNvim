# Multi-Agent Workflow Runtime (`docs/workflow/`)

本目录按**迭代（Iteration）**存放科研实验或工程开发项目的跨 Agent 交接文档与四方审查记录（历史迭代完整归档，结合 Git 提交追踪）：

```text
docs/workflow/
├── iter-log.md                      # 项目整体迭代演进总日志（目标、关键 Git Commit、审查结论、实验/交付结果）
├── iter-001-<slug>/                 # 第 1 轮 Plan → Exec → Review 迭代闭环
│   ├── plan.md                      # 规划方案（科研假设/张量维度，或工程架构/接口契约/边界与测试计划）
│   ├── exec_report.md               # 代码改动摘要、Git Commit 范围与冒烟/单元测试输出证据
│   ├── result.md                    # 本轮最终验证/实验结果摘要（交回 Plan agy 决策下一轮）
│   └── reviews/                     # 本轮各审查轮次（round1/round2/round3）的共享 Prompt 与四方原始意见
│       ├── prompt_plan_round1.md
│       ├── plan_round1_gemini.md
│       ├── plan_round1_deepseek.md
│       ├── plan_round1_glm.md
│       └── plan_round1_codex.md
└── iter-002-<slug>/                 # 第 2 轮迭代闭环（基于上一轮结论推进）
    └── ...
```
