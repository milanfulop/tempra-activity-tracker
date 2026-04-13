import express from 'express';
import entryRouter from './routes/entries';
import categoryRouter from './routes/categories';
import statisticsRouter from './routes/statistics';
import userRouter from './routes/user';

const app = express();

app.use(express.json());

app.use('/entry', entryRouter);
app.use('/category', categoryRouter);
app.use('/stats', statisticsRouter);
app.use('/user', userRouter);

export default app;