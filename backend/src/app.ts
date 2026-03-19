import express from 'express';
import entryRouter from './routes/entries';
import categoryRouter from './routes/categories';
import statisticsRouter from './routes/statistics';

const app = express();

app.use(express.json());

app.use('/entry', entryRouter);
app.use('/category', categoryRouter);
app.use('/stats', statisticsRouter);

export default app;