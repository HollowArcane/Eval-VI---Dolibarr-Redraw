import gleam/option.{Some, None}
import input
import gleam/int
import toolkit_util/results
import gleam/string
import simplifile
import gleam/list
import gleam/result
import argv
import glance.{type Definition, type CustomType, type Variant, type Type}
import gleam/io

pub fn main()
{
    // TODO:
    //  allow user to just specify typename and the formatter will try to guess which type it was referring to
    // auto-import the module if it is not already imported
    // allow formatting types with multiple variants

    let argv.Argv(arguments:, ..) = argv.load()
    use type_name <- results.guard_error(list.first(arguments), fn(_) {
        io.println("Required argument: type name")
    })

    // get all files
    use src_files <- results.guard_error(simplifile.get_files("src"), fn(e) {
        io.println("Error getting files: " <> string.inspect(e))
    })
    use test_files <- results.guard_error(simplifile.get_files("test"), fn(e) {
        io.println("Error getting files: " <> string.inspect(e))
    })
    let files = src_files |> list.append(test_files)

    let modules = {
        // try to find the type in each file
        let error_handler = fn(e, modules)
        {
            io.println(e)
            modules
        }

        use modules, file <- list.fold(files, [])

        let module = simplifile.read(file)
            |> result.map_error(fn(e) {"Error reading file: " <> string.inspect(e)})
        use module <- results.guard_error(module, error_handler(_, modules))
        
        let module = glance.module(module)
            |> result.map_error(fn(e) {"Error parsing module: " <> string.inspect(e)})
        use module <- results.guard_error(module, error_handler(_, modules))
        
        let import_ = module.imports
            |> list.find(fn(imp) {imp.definition.module == "toolkit_util/data"})
            |> option.from_result


        use type_ <- results.guard_error({
            use type_ <- list.find(module.custom_types)
            type_.definition.name == type_name
        }, fn(_) {modules})

        // collect file and type
        [#(file, type_, import_), ..modules]
    }

    case modules
    {
        // if no files found, then error
        [] -> io.println("No files found with type: " <> type_name)
        [#(file, type_, import_)] -> render_and_override(file, type_, import_)
        // if multiple files found, then let user choose
        [_, _, ..] -> {
            io.println("Multiple file found containing the given type: " <> type_name)
            io.println("Please specify the type name more precisely or choose one of the following files:")
            {
                use #(path, _, _), i <- list.index_map(modules)
                io.println(" " <> int.to_string(i + 1) <> " - " <> path <> "." <> type_name)
            }
            use choice_index <- results.guard_error(input.input("")
                |> result.try(int.parse), fn(_) {
                io.println("Could not read user input")
            })
            let choice = list.drop(modules, choice_index - 1)
                |> list.first
            use #(file, type_, import_) <- results.guard_error(choice, fn(_) {
                io.println("Invalid choice: " <> int.to_string(choice_index))
            })
            render_and_override(file, type_, import_)
        }
    }
}

pub fn render_and_override(filename: String, type_: Definition(CustomType), import_)
{
    // render type format
    use function <- results.guard_error(render_format(type_), fn(e) {
        io.println("Error rendering format function: " <> string.inspect(e))
    })
    // override file
    use file <- results.guard_error(simplifile.read(filename), fn(e) {
        io.println("Error reading file: " <> string.inspect(e))
    })

    let content = file <> "\n" <> function
    let content = case import_
    {
        Some(_) -> content
        None -> "import toolkit_util/data\n" <> content
    }

    use _ <- results.guard_error(simplifile.write(filename, content), fn(e) {
        io.println("Error writing file: " <> string.inspect(e))
    })
    Nil
}

fn render_format(custom_type: Definition(CustomType))
{
    case custom_type.definition.variants
    {
        [variant] -> {
            use format <- result.map(render_format_one("model", variant))

            "pub fn format(model: " <> custom_type.definition.name <> ")\n" <>
            "{\n" <>
            format <> "\n"
            <> "}\n"
        }
        _ -> Error("Multiple variants are not supported")
    }
}

fn render_format_one(model_name, variant: Variant)
{
    use fields <- result.map(format_fields(model_name, variant.fields))
    "\t[\n" <>
    "\t\t" <> string.join(fields, ",\n\t\t") <> "\n" <>
    "\t]"
}

fn format_fields(model_name, fields: List(glance.VariantField))
{
    use field <- list.try_map(fields)
    case field
    {
        glance.UnlabelledVariantField(_) ->
            Error("Unlabelled variant fields are not supported")
        glance.LabelledVariantField(item:, label:) -> 
            Ok("#(\"" <> label <> "\", " <> render_format_type(model_name, item, label) <> ")")
    }
}

fn render_format_type(model_name, type_: Type, label: String)
{
    case type_
    {
        glance.NamedType(name:, parameters:, ..) -> case name, parameters
        {
            "String", _ ->
                model_name <> "." <> label <> " |> data.String"
            "Int", _ ->
                model_name <> "." <> label <> " |> data.Int"
            "Float", _ -> 
                model_name <> "." <> label <> " |> data.Float"
            "Bool", _ -> 
                model_name <> "." <> label <> " |> data.Bool"
            "Date", _ -> 
                model_name <> "." <> label <> " |> data.Date"
            "Time", _ -> 
                model_name <> "." <> label <> " |> data.Time"
            "Calendar", _ -> 
                model_name <> "." <> label <> " |> data.Datetime"
            "Option", [glance.NamedType(name:"String", ..)] -> 
                model_name <> "." <> label <> " |> option.map(data.String) |> option.unwrap(data.Other(Nil))"
            "Option", [glance.NamedType(name:"Int", ..)] -> 
                model_name <> "." <> label <> " |> option.map(data.Int) |> option.unwrap(data.Other(Nil))"
            "Option", [glance.NamedType(name:"Float", ..)] -> 
                model_name <> "." <> label <> " |> option.map(data.Float) |> option.unwrap(data.Other(Nil))"
            "Option", [glance.NamedType(name:"Bool", ..)] -> 
                model_name <> "." <> label <> " |> option.map(data.Bool) |> option.unwrap(data.Other(Nil))"
            "Option", [glance.NamedType(name:"Date", ..)] -> 
                model_name <> "." <> label <> " |> option.map(data.Date) |> option.unwrap(data.Other(Nil))"
            "Option", [glance.NamedType(name:"Time", ..)] -> 
                model_name <> "." <> label <> " |> option.map(data.Time) |> option.unwrap(data.Other(Nil))"
            "Option", [glance.NamedType(name:"Calendar", ..)] -> 
                model_name <> "." <> label <> " |> option.map(data.Datetime) |> option.unwrap(data.Other(Nil))"
            "Option", [_] -> 
                model_name <> "." <> label <> " |> option.map(todo as \"formatter for inner type\") |> option.unwrap(data.Other(Nil))"
            _, _ -> 
                model_name <> "." <> label <> " |> todo as \"formatter for " <> name <> "\" |> data.Other"
        }

        glance.FunctionType(..) -> 
                model_name <> "." <> label <> " |> todo as \"formatter for fn(..) -> a\" |> data.Other"

        glance.HoleType(name:, ..) -> 
                model_name <> "." <> label <> " |> todo as \"formatter for " <> name <> "\" |> data.Other"

        glance.TupleType(..) ->
                model_name <> "." <> label <> " |> todo as \"formatter for #(..)\" |> data.Other"

        glance.VariableType(name:, ..) ->
                model_name <> "." <> label <> " |> todo as \"formatter for " <> name <> "\" |> data.Other"
    }   
}