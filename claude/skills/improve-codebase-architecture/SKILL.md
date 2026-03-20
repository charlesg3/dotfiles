# Improve Codebase Architecture

Explore a codebase like an AI would, surface architectural friction, discover opportunities for improving testability, and propose module-deepening refactors as GitHub issue RFCs.

A **deep module** (John Ousterhout, "A Philosophy of Software Design") has "a small interface hiding a large implementation." Deep modules offer enhanced testability, improved AI-navigability, and enable boundary-level testing rather than internal testing.

## Process

### 1. Explore the codebase

Use the Agent tool with subagent_type=Explore to navigate the codebase naturally. Avoid rigid heuristics—instead, explore organically and document friction points:

- Understanding one concept requires jumping between numerous small files
- Modules are so shallow that the interface rivals the implementation in complexity
- Pure functions extracted solely for testing purposes, while actual bugs lurk in their invocation patterns
- Tightly-coupled modules generate integration risk at their boundaries
- Sections lacking tests or presenting testing challenges

The friction encountered serves as the primary signal.

### 2. Present candidates

Provide a numbered list of deepening opportunities. Each candidate should include:

- **Cluster**: Involved modules and concepts
- **Why they're coupled**: Shared types, invocation patterns, joint concept ownership
- **Dependency category**: Reference [REFERENCE.md](REFERENCE.md) for the four categories
- **Test impact**: Existing tests replaced by boundary tests

Refrain from proposing interfaces yet. Instead, ask: "Which of these would you like to explore?"

### 3. User picks a candidate

### 4. Frame the problem space

Before spawning sub-agents, prepare a user-facing explanation of the problem space:

- New interface constraints
- Required dependencies
- Illustrative code sketch grounding the constraints (not a formal proposal)

Present this to the user, then proceed immediately to Step 5. The user reflects while sub-agents work concurrently.

### 5. Design multiple interfaces

Spawn 3+ sub-agents in parallel using the Agent tool. Each produces a **radically different** interface for the deepened module.

Supply each sub-agent with a separate technical brief (file paths, coupling details, dependency category, hidden elements). Assign each agent a distinct design constraint:

- Agent 1: "Minimize the interface — aim for 1-3 entry points max"
- Agent 2: "Maximize flexibility — support many use cases and extension"
- Agent 3: "Optimize for the most common caller — make the default case trivial"
- Agent 4 (if applicable): "Design around the ports & adapters pattern for cross-boundary dependencies"

Each sub-agent delivers:

1. Interface signature (types, methods, params)
2. Usage example demonstrating caller interaction
3. Hidden internal complexity
4. Dependency strategy (consult [REFERENCE.md](REFERENCE.md))
5. Trade-offs

Present designs sequentially, then compare them in prose. Offer your own recommendation: which design demonstrates greatest strength and reasoning. If elements from different designs merge well, propose a hybrid. Be opinionated—users value strong analysis over neutral menus.

### 6. User picks an interface (or accepts recommendation)

### 7. Create GitHub issue

Generate a refactor RFC as a GitHub issue using `gh issue create`. Follow the template in [REFERENCE.md](REFERENCE.md). Do NOT request user review before creating—simply create and share the URL.
