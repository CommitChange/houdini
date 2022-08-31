// License: LGPL-3.0-or-later
type CompletionState = "ready" | "running" | "completed";

export default class CompletablePromiseManager {
  state: CompletionState = "ready";
  
  async process<T>(promise:() => Promise<T>) : Promise<T | "running" | "completed" > {
    try {
      if (this.state == "ready") {
        this.state = "running"
        const result = await promise();
        this.state = "completed"

        return result;
      }
      else {
        return this.state;
      }
    }
    catch(e) {
      this.state = "ready";
      throw e;
    }
  }
}