import { WebSocketGateway, WebSocketServer } from '@nestjs/websockets';
import type { Server } from 'socket.io';

@WebSocketGateway({ namespace: '/realtime', cors: { origin: false } })
export class RealtimeGateway {
  @WebSocketServer() server!: Server;
  configurationUpdated(payload: { key: string; version: number; updatedAt: Date }): void { this.emit('CONFIGURATION_UPDATED', 'ConfigurationUpdated', payload); }
  featureFlagChanged(payload: { key: string; version: number; updatedAt: Date }): void { this.emit('FEATURE_FLAG_UPDATED', 'FeatureFlagChanged', payload); }
  contentUpdated(payload: { key: string; version: number; updatedAt: Date }): void { this.emit('DYNAMIC_CONTENT_UPDATED', 'DynamicContentUpdated', payload); }
  notificationCreated(payload: { id: string; createdAt: Date }): void { this.emit('NOTIFICATION_CREATED', 'NotificationCreated', payload); }
  userStatusChanged(payload: { userId: string; status: string }): void { this.emit('USER_STATUS_CHANGED', 'UserStatusChanged', payload); }
  transactionUpdated(payload: { transactionId: string; status: string }): void { this.emit('TRANSACTION_UPDATED', 'TransactionUpdated', payload); }
  private emit<T>(canonical: string, legacy: string, payload: T): void { this.server.emit(canonical, payload); this.server.emit(legacy, payload); }
}
