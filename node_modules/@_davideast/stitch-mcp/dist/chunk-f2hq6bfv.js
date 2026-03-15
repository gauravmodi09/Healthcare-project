// src/framework/StepRunner.ts
async function runSteps(steps, context, callbacks) {
  const results = [];
  for (const step of steps) {
    if (await step.shouldRun(context)) {
      callbacks?.onBeforeStep?.(step, context);
      const result = await step.run(context);
      results.push(result);
      const shouldStop = callbacks?.onAfterStep?.(step, result, context) ?? false;
      if (shouldStop) {
        return { results, completed: false, stoppedAt: { step: step.id, result } };
      }
    } else {
      callbacks?.onSkippedStep?.(step, context);
    }
  }
  return { results, completed: true };
}

export { runSteps };

//# debugId=E025FCFB6F028A6A64756E2164756E21
