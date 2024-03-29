# TIL: Running Python code as a migration operation in Django

2023-08-21

When I started learning Django, I was confused with the difference between `makemigrations` and `migrate` commands. I got it after a while, but I never truly had to work with complex migrations or write custome ones. I recently had to write a custom migration to change a `ForeignKey` field to a `OneToOneField` and I used the [RunSQL](https://docs.djangoproject.com/en/4.2/ref/migration-operations/#runsql) special operation which allows to run raw sql queries. It allowed me to better understand migrations and gave me the confidence to push my changes in production.

Now I wanted to refactor an unnecessary many-to-many model into a one-to-one field in another model. The models looked like the following code:

```python
from accounts import models as account_models


# the model I want to get rid of
class HomeAddress(BaseModel):
    home = models.ForeignKey(Home, on_delete=models.CASCADE)
    address = models.ForeignKey(
        account_models.Address,
        on_delete=models.CASCADE,
    )
    class Meta:
        verbose_name_plural = "home addresses"


class Home(BaseModel):
    name = models.CharField(max_length=50, default="Home")
    address = models.OneToOneField(  # the field I want to replace the model with
        account_models.Address,
        on_delete=models.PROTECT,
    )

```

The challenge was to copy the `Address` refered in each `HomeAddress` row to the refered `Home`. I wasn't sure how I would solve this and dreaded the raw SQL query, not wanting to mess up the production data. I asked ChatGPT for some inspiration and it suggested using the [RunPython](https://docs.djangoproject.com/en/4.2/ref/migration-operations/#runpython) special operation. You first declare a function that takes two arguments; the first being the name of the app containing the historical models that matches the operation and the second is an instance of [SchemaEditor](https://docs.djangoproject.com/en/4.2/ref/schema-editor/#django.db.backends.base.schema.BaseDatabaseSchemaEditor) the class that turns operations into SQL. The function code describes the changes that will be applied.

A second function is declared that accepts the same two arguments and its code should undo what has been done by the first function. This makes the migration reversible otherwise the changes are permanent. The two functions are passed to the `RunPython` function called inside the `operations` list of the `Migration` class. For database backends that do not support [Data Definition Language (DDL)](https://en.wikipedia.org/wiki/Data_definition_language) transactions (`CREATE`, `ALTER`, etc.), `RunPython` will run its content inside a transaction.

For databases that do support DDL like PostgreSQL, no other transactions are added besides the one generated by a migration. A migration with both schema changes and `RunPython` operation will raise an exception stating the changes cannot be applied because it has pending trigger events.

What I ended up doing is generating a migration to add the `Home.address` field, then generated an empty migration and wrote the following code:

```python
from django.db import migrations

from accounts import models as account_models


def replace_home_with_address(apps, schema_editor):
    home_address_model = apps.get_model('my_app', 'HomeAddress')

    for home_address in home_address_model.objects.all():
        address = home_address.address
        address = account_models.Address.objects.create(
	    address_line_1=f"123 Fake Street",
	    address_line_2="Building 1",
	    city="Test City",
	    zip_code="12345",
	    country_id=home_address.address.country.id,
	    subdivision_id=home_address.address.subdivision.id,
        )
        home_address.home.address_id = address.id
        home_address.home.save()


class Migration(migrations.Migration):

    dependencies = [
        ('my_app', '0002_auto_20230821_1308'),
    ]

    operations = [
        migrations.RunPython(replace_home_with_address),
    ]

```

So here, I loop over the `HomeAddress` rows and for each one of them, I put the `HomeAddress.address` reference into `HomeAddress.home.address` and save. Note that for readability purpose, I didn't include the query prefetching code.
