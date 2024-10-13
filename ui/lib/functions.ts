export interface Function {
  name: string;
  description: string;
  execute: () => void;
}

export const functions: Record<string, Function> = {
  showImages: {
    name: 'showImages',
    description: 'Display images of hotels or destinations',
    execute: () => {
      console.log('Showing images');
    },
  },
  analyzeReviews: {
    name: 'analyzeReviews',
    description: 'Analyze reviews for a specific hotel',
    execute: () => {
      console.log('Analyzing reviews');
    },
  },
  bookRoom: {
    name: 'bookRoom',
    description: 'Initiate the room booking process',
    execute: () => {
      console.log('Booking room');
    },
  },
};
