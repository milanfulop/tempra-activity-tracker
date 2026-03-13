import express from 'express';
import router from './routes/entries';

const app = express();

app.use(express.json());

router.use('/entries', router);

export default app;