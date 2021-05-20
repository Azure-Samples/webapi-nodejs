import items from './items';
import { Express } from 'express'; 

export default function mountRoutes(app: Express) {
  app.use('/items', items)
}
