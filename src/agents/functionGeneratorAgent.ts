import { RunnableSequence, RunnableMap } from '@langchain/core/runnables';
import ListLineOutputParser from '../lib/outputParsers/listLineOutputParser';
import { PromptTemplate } from '@langchain/core/prompts';
import formatChatHistoryAsString from '../utils/formatHistory';
import { BaseMessage } from '@langchain/core/messages';
import { BaseChatModel } from '@langchain/core/language_models/chat_models';
import { ChatOpenAI } from '@langchain/openai';

const functionGeneratorPrompt = `
You are an AI function suggestion generator for an AI-powered travel agent application. You will be given a conversation below which is related to travel or hotel experiences. You need to generate 2-3 function suggestions based on this conversation. The functions should be relevant to the conversation and can be used to provide additional functionality to the user.

Available functions:
- showImages: Display images of hotels or destinations
- analyzeReviews: Analyze reviews for a specific hotel
- bookRoom: Initiate the room booking process

Provide these function suggestions separated by newlines between the XML tags <functions> and </functions>. Here are some examples:

<functions>
showImages
analyzeReviews
bookRoom
</functions>

Conversation:
{chat_history}
`;

type FunctionGeneratorInput = {
  chat_history: BaseMessage[];
};

const outputParser = new ListLineOutputParser({
  key: 'functions',
});

const createFunctionGeneratorChain = (llm: BaseChatModel) => {
  return RunnableSequence.from([
    RunnableMap.from({
      chat_history: (input: FunctionGeneratorInput) =>
        formatChatHistoryAsString(input.chat_history),
    }),
    PromptTemplate.fromTemplate(functionGeneratorPrompt),
    llm,
    outputParser,
  ]);
};

const generateFunctions = (
  input: FunctionGeneratorInput,
  llm: BaseChatModel,
) => {
  (llm as unknown as ChatOpenAI).temperature = 0;
  const functionGeneratorChain = createFunctionGeneratorChain(llm);
  return functionGeneratorChain.invoke(input);
};

export default generateFunctions;

