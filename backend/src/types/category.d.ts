export default interface Category {
    id: string,
    user_id: string,
    name: string,
    color: string,
    is_productive: boolean,
    is_sleep: boolean,
    created_at: Date,
}