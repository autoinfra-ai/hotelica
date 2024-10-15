import { pgTable, text, serial, uuid, jsonb, timestamp } from 'drizzle-orm/pg-core';

export const messages = pgTable('messages', {
  id: serial('id').primaryKey(),
  content: text('content').notNull(),
  chatId: text('chatId').notNull(),
  messageId: text('messageId').notNull(),
  role: text('role', { enum: ['assistant', 'user'] }),
  metadata: jsonb('metadata'),
});

export const chats = pgTable('chats', {
    id: text('id').primaryKey(),
    title: text('title').notNull(),
  createdAt: timestamp('createdAt').notNull().defaultNow(),
  focusMode: text('focusMode').notNull(),
});
