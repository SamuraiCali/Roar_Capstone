export interface UploadVideoRequest {
    userId: number,
    key: string,
    title: string,
    description: string | null,
    sports: string[]
}