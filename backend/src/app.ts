import express from 'express';
import entryRouter from './routes/entries';
import categoryRouter from './routes/categories';

const app = express();

app.use(express.json());

app.use('/entry', entryRouter);
app.use('/category', categoryRouter);

export default app;