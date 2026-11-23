// License: LGPL-3.0-or-later

import noop from 'lodash/noop';

import StateManager, { DonationResult } from "./StateManager";
import { CallbackControllerBuilder } from '../../../../../app/javascript/common/Callbacks';


import PlausibleCallback, { GetPlausible } from './PlausibleCallback';
import type { CallbackAccessor, CallbackFilters, CallbackMap, CallbackClass } from "../../../../../app/javascript/common/Callbacks/types";

interface DonationSubmitterProps {
  getPlausible?: GetPlausible,
}

type ActionNames = 'success'

export default class DonationSubmitter implements EventTarget, CallbackAccessor<DonationSubmitter, ActionNames> {

  
  private stateManager = new StateManager();

  private eventTarget = new EventTarget();

  private callbackController = new CallbackControllerBuilder('success').withInputType<DonationSubmitter>();

  constructor(public readonly props: DonationSubmitterProps) {
    this.callbackController.addAfterCallback('success', PlausibleCallback);

    this.stateManager.addEventListener('beginSubmit', this.handleBeginSubmit);
    this.stateManager.addEventListener('savedCard', this.handleSavedCard);
    this.stateManager.addEventListener('errored', this.handleErrored);

    this.stateManager.addEventListener('completed', this.handleCompleted);

  }


  get loading(): boolean {
    return this.stateManager.loading;
  }

  get error():string|undefined {
    return this.stateManager.error;
  }

  get progress(): number|undefined {
    return this.stateManager.progress;
  }

  get completed(): boolean {
    return this.stateManager.completed;
  }

  get result(): DonationResult|undefined {
    return this.stateManager.result;
  }

  private async postSuccess(): Promise<void> {
    await this.callbackController.run('success', this, noop);
  }

  callbacks(): CallbackMap<DonationSubmitter, ActionNames>;
  callbacks(actionName: ActionNames): CallbackFilters<CallbackClass<DonationSubmitter>> | undefined;
  callbacks(actionName?: ActionNames): CallbackMap<DonationSubmitter, ActionNames> | CallbackFilters<CallbackClass<DonationSubmitter>> | undefined {
    return this.callbackController.callbacks(actionName);
  }

  public reportBeginSubmit(): void {
    this.stateManager.reportBeginSubmit();
  }

  public reportError(error:string):void {
    this.stateManager.reportError(error);
  }

  public reportSavedCard(): void {
    this.stateManager.reportSavedCard();
  }

  public reportCompleted(result:DonationResult): void {
    this.stateManager.reportCompleted(result);
  }

  addEventListener(type: 'updated', listener: EventListenerOrEventListenerObject, options?: boolean | AddEventListenerOptions): void {
    this.eventTarget.addEventListener(type, listener, options);
  }
  dispatchEvent(event: Event): boolean {
    return this.eventTarget.dispatchEvent(event);
  }
  removeEventListener(type: 'updated', callback: EventListenerOrEventListenerObject, options?: boolean | EventListenerOptions): void {
    this.eventTarget.removeEventListener(type, callback, options);
  }

  private handleCompleted = (_evt: Event) => {
    this.postSuccess();
    this.dispatchEvent(new Event('updated'));
  }
  
  private handleErrored = (_evt: Event) => {
    this.dispatchEvent(new Event('updated'));
  }
  
  private handleSavedCard = (_evt: Event) => {
    this.dispatchEvent(new Event('updated'));
  }
  
  private handleBeginSubmit = (_evt: Event) => {
    this.dispatchEvent(new Event('updated'));
  }
}