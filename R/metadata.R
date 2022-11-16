## document metadata

## note: this is run outside of the targets workflow
library(dataspice)
create_spice(dir = "data/Output/")

prep_access(data_path = "data/Output",
            access_path = "data/Output/metadata/access.csv",
            recursive = TRUE)


prep_attributes(data_path = "data/Output",
                attributes_path = "data/Output/metadata/attributes.csv",
                recursive = TRUE)


edit_attributes(metadata_dir = "data/Output/metadata")
