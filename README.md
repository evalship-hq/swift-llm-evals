# LLM evals for Swift

A Swift support bot whose AI call is tested on every pull request with [tinyeval](https://tinyeval.com).

## Run it

Clone this repo, or use it as a template. Then:

```sh
export ANTHROPIC_API_KEY=sk-ant-...
swift build -c release   # the first build takes a while; later runs start fast
./tinyeval
```

```
support
  ✓ refund after the window 9.7s
  ✓ missing package 8.0s
  ✓ refund inside the window 10.4s

All 3 evals passed (eval-results.json)
```

## What's here

- `Sources/Support/Support.swift`: the bot. `Support().answer(message)` sends the message to Claude and returns the reply. Swift has no official Anthropic SDK, so it calls the Messages API with URLSession and Codable.
- `prompts/support.md`: the system prompt.
- `Sources/evalworker/main.swift`: the tinyeval worker. It builds `Support` once, then answers each test case.
- `evals/support.sh`: three test cases, each checked by a regex, a judge or both.
- `tinyeval`: the eval runner, one bash file.
- `.github/workflows/evals.yml`: runs the evals on every pull request and push to main.

## Use it for your app

1. Replace `answer` with your AI call. Keep the worker, so your app starts once per worker and not once per test case.
2. Write your test cases in `evals/`. The [check lines](https://github.com/evalship-hq/tinyeval#writing-evals) cover regexes, JSON, your own graders and a model judge.
3. In an iOS or macOS app, keep the AI call in a Swift package or a target without UIKit or SwiftUI imports, so the worker can call it from the command line. The bot reads its prompt from the checkout, so make the prompt a resource in an app you ship.
4. In a Vapor app, build the service once in the worker and call it in the loop.

When the API call fails for a reason that isn't your code, such as a missing key, a rate limit or a timeout, the worker replies `#tinyeval couldnt_run`. tinyeval then counts the test case as couldn't run, not as failed.

## In CI

Add `ANTHROPIC_API_KEY` as a repository secret under **Settings** > **Secrets and variables** > **Actions**. The bot and tinyeval's judge both use it.

The workflow builds the package with the Swift that ubuntu-latest ships, and caches `.build`. Then it runs each test case 3 times, and a test case passes when at least 2 of the 3 pass. A failing eval fails the job, so you can require it before merging. The results upload as the `eval-results` artifact, also when an eval fails.

Without the secret, the workflow skips the evals and prints a notice. Pull requests from forks get no secrets, so their evals skip too.

## Compare pull requests with main

A fresh CI run has no earlier run to compare with. [evalship](https://evalship.com) reads `eval-results.json`, compares each pull request with main, tells flaky evals from real drops and comments on the pull request.

## License

MIT. See [LICENSE](LICENSE).
