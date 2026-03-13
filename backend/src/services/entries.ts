import { Response } from 'express';

function getEntries(userId: string) {
    return "get"
}

function createEntry(userId: string) {
    return "create"
}

function updateEntry(userId: string) {
    return "update"
}

function deleteEntry(userId: string) {
    return "delete"
}

export { getEntries, createEntry, updateEntry, deleteEntry };