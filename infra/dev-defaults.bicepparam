using none
extends './global.bicepparam'

param environmentTags = {
    ...base.environmentTags
    Environment: 'Development'
}
