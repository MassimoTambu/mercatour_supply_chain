import { getDatabase } from "../config";

const db = getDatabase();

db.serialize(() => {
    db.run("CREATE TABLE users (info TEXT)");
});

db.close();
