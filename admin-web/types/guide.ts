export interface Guide {
  id: string;
  injuryId: string;
  title: string;
  description: string;
  symptoms: string[];
  steps: string[];
  warnings: string[];
  whenToSeekHelp: string[];
  explanation: string;
  dos: string[];
  donts: string[];
  imagePath?: string;
  audioPath?: string;
}