import { RunnableSequence, RunnableMap } from '@langchain/core/runnables';
import ListLineOutputParser from '../lib/outputParsers/listLineOutputParser';
import { PromptTemplate } from '@langchain/core/prompts';
import formatChatHistoryAsString from '../utils/formatHistory';
import { BaseMessage } from '@langchain/core/messages';
import { BaseChatModel } from '@langchain/core/language_models/chat_models';
import { ChatOpenAI } from '@langchain/openai';

const suggestionGeneratorPrompt = `
You are an AI suggestion generator for an AI-powered travel agent application. You will be given a conversation below which is related to travel or hotel experiences. You need to generate 4-5 suggestions based on this conversation. The suggestions should be relevant to the conversation and can be used by the user to ask the chat model for more information about travel or hotels.
Make sure the suggestions are in the form of questions that users might ask when planning travel or seeking hotel information. For example:
Ensure the suggestions are specific, realistic, and reflect common travel queries:

Try to understand the user's intent from the conversation to tailor the suggestions effectively. For example, if the user mentions a specific destination, focus suggestions around that location.

Provide these suggestions separated by newlines between the XML tags <suggestions> and </suggestions>. Here are some examples of travel-related suggestions:

<suggestions>
What are the best hotels near the Eiffel Tower?
How far is the airport from downtown?
Can you show me bad reviews for Hotel X?
What are some must-see attractions in Paris?
</suggestions>

Conversation:
{chat_history}
`;

type SuggestionGeneratorInput = {
  chat_history: BaseMessage[];
};

const outputParser = new ListLineOutputParser({
  key: 'suggestions',
});

const createSuggestionGeneratorChain = (llm: BaseChatModel) => {
  return RunnableSequence.from([
    RunnableMap.from({
      chat_history: (input: SuggestionGeneratorInput) =>
        formatChatHistoryAsString(input.chat_history),
    }),
    PromptTemplate.fromTemplate(suggestionGeneratorPrompt),
    llm,
    outputParser,
  ]);
};

const generateSuggestions = (
  input: SuggestionGeneratorInput,
  llm: BaseChatModel,
) => {
  (llm as unknown as ChatOpenAI).temperature = 0;
  const suggestionGeneratorChain = createSuggestionGeneratorChain(llm);
  return suggestionGeneratorChain.invoke(input);
};

export default generateSuggestions;
