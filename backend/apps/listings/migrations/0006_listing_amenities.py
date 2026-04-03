from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('listings', '0005_availabilityday'),
    ]

    operations = [
        migrations.AddField(
            model_name='listing',
            name='amenities',
            field=models.JSONField(blank=True, default=list),
        ),
    ]
