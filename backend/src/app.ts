import express from 'express';
import entryRouter from './routes/entries';

const app = express();

app.use(express.json());

app.use('/entry', entryRouter);

export default app;