import express from 'express';
import generateFunctions from '../agents/functionGeneratorAgent';
import { BaseChatModel } from '@langchain/core/language_models/chat_models';
import { getAvailableChatModelProviders } from '../lib/providers';
import { HumanMessage, AIMessage } from '@langchain/core/messages';
import logger from '../utils/logger';

const router = express.Router();

router.post('/', async (req, res) => {
  try {
    let { chat_history, chat_model, chat_model_provider } = req.body;

    chat_history = chat_history.map((msg: any) => {
      if (msg.role === 'user') {
        return new HumanMessage(msg.content);
      } else if (msg.role === 'assistant') {
        return new AIMessage(msg.content);
      }
    });

    const chatModels = await getAvailableChatModelProviders();
    const provider = chat_model_provider ?? Object.keys(chatModels)[0];
    const chatModel = chat_model ?? Object.keys(chatModels[provider])[0];

    let llm: BaseChatModel | undefined;

    if (chatModels[provider] && chatModels[provider][chatModel]) {
      llm = chatModels[provider][chatModel].model as BaseChatModel | undefined;
    }

    if (!llm) {
      res.status(500).json({ message: 'Invalid LLM model selected' });
      return;
    }

    const functionSuggestions = await generateFunctions({ chat_history }, llm);

    res.status(200).json({ functions: functionSuggestions });
  } catch (err) {
    res.status(500).json({ message: 'An error has occurred.' });
    logger.error(`Error in generating function suggestions: ${err.message}`);
  }
});

export default router;

