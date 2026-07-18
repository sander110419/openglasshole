# AI provenance

## Disclosure

All code, CAD, schematics, documentation, tests, and repository-native images
in the recorded generation run were produced or edited by OpenAI Codex. The
human requester supplied the natural-language prompts and publication direction
shown below, but did not manually author or edit the implementation artifacts
during that run.

Accordingly, **fully AI-generated** describes the repository artifacts, and
**zero input from the requester** means zero manually authored code, CAD,
schematics, documentation, tests, or images. It cannot literally mean zero
human direction: the prompts themselves are human input. The PNG model images
are deterministic renders of the AI-authored OpenSCAD source, not photographs
or evidence of a physical build.

## Recorded generation time

The frozen product-generation interval begins with the first product prompt at
**2026-07-17 20:29:10.851 UTC** and ends with delivery of the compact/walking
revision at **2026-07-18 01:33:36.378 UTC**.

**Elapsed wall-clock time: 5 hours, 4 minutes, 25.527 seconds.**

This wall-clock interval includes research, tool execution, builds, CAD renders,
GitHub Actions, coordination between Codex agents, and waiting time. It is not a
claim of five continuous hours of model inference. The later administrative
rename/provenance request is reproduced below but excluded from this frozen
duration.

## Token accounting

Codex's final cumulative `token_count` events were summed across the root agent
and nine specialist subagents at the same delivery cutoff.

| Accounted category | Tokens |
| --- | ---: |
| Input | 534,252,435 |
| of which cached input | 513,921,280 |
| Output | 2,388,323 |
| of which reasoning output | 1,345,959 |
| **Total input + output** | **536,640,758** |

Cached input is already included in input, and reasoning output is already
included in output; neither subset should be added to the total again. These
are model-accounting tokens, not words or unique source text. They include
repeated and cached system/conversation context plus tool output processed by
the agents. They are not a billing or cost estimate.

The raw Codex rollout logs contain the complete conversation and local
environment context, so they are intentionally not committed. The snapshot
uses ten related sessions: the root, optics/BOM, power/firmware, mechanical,
repository review, CAD/optics audit, final mechanical audit, mini-optics audit,
glance-firmware, and hinge-stop calculation sessions. The later rename and
provenance agents are excluded so publishing this record does not move its own
measurement boundary.

## User-authored project prompts, verbatim

### Prompt 1 — initial build

Timestamp: **2026-07-17 20:29:10.851 UTC**

```text
create a new github project under de ~/Dev folder called openglasshole, create a CHEAP open source, clip-on HUD system I can clip on to my glasses. it needs to be extremely low powered, and be able to display text either on my prescription glasses, or have a glass pane in front of it on which I can see text. The (ideally scrolling) text it needs to display should be received from a server using a lightweight API call. I want to use this as some sort of autocue. Include a 3d model if possible, and schematics to build it including a guide. It needs to be easy, with not too many parts, and it needs to be cheap (esp32 or similar) including wifi. I have access o a 3D printer and can order any parts necessary, but battery life and simplicity is very important. Ideally the total project should come in UNDER 50$, not be too bulky, and easy to clip on to any glasses, ideally with an integrated battery, but an external battery mounted elsewhere on the glasses in a separate housing is also allowed.
```

### Prompt 2 — compact walking revision

Timestamp: **2026-07-17 23:59:58.995 UTC**

```text
add an image of the 3D model, make sure it can also be used pleasantly while walking, outdoor is not needed, but if you can, that would be great. find other improvements you can make to make it as small as possible without reducing functionality. if it is a major improvement for just a few extra dollars, add it as an option.
```

### Prompt 3 — publication and provenance

Timestamp: **2026-07-18 01:33:36.411 UTC**

This administrative prompt is recorded for completeness but is outside the
time/token cutoff above.

```text
Create the new github repo publicly under sander110419 and rename it to open-occucue, add that it is fully A.I generated with 0 input from me, add the prompts I used, the time you took, and how many tokens are used. commit and push to the new repo
```

System, developer, tool, safety, and environment instructions are not
user-authored project requests and are not reproduced here.
